/*
 Infomaniak Calendar - iOS App
 Copyright (C) 2026 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import CalendarCore
import CalendarCoreUI
@testable import CalendarEventFormView
import Foundation
import Testing

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct LocationPickerViewModelTests {
    @Test(arguments: [
        ("", "Place"),
        ("Street", "Place, Street"),
        ("Place", "Place"),
        ("Place, Street", "Place, Street")
    ])
    func placeLocationDoesNotDuplicateItsName(address: String, expected: String) {
        let place = LocationPlace(id: "place", name: "Place", address: address)
        #expect(place.location == .place(text: expected))
    }

    @Test
    func roomsRenderBeforeAvailabilityAndSortAsStatusesArrive() async {
        let service = RoomsStub()
        service.rooms = [
            room("unavailable", "Alpha"),
            room("unknown", "Beta"),
            room("unknown-explicit", "Delta"),
            room("available", "Gamma")
        ]
        let started = Gate<Bool>()
        let response = Gate<[String: MeetingRoomAvailability]>()
        service.availabilityHandler = { _ in
            started.open(true)
            return await response.wait()
        }
        let model = makeModel(rooms: service)
        await model.observeRooms(calendarId: "calendar")
        let task = Task { await model.loadAvailability(for: request()) }
        _ = await started.wait()

        #expect(service.observedCalendarIds == ["calendar"])
        #expect(model.rooms.count == 4)
        #expect(model.availability.isEmpty)
        #expect(model.isLoading)
        #expect(model.visibleRooms(query: "").map(\.id) == ["unavailable", "unknown", "unknown-explicit", "available"])
        #expect(model.availability(for: "available") == .unknown)

        response.open(["available": .available, "unavailable": .unavailable, "unknown-explicit": .unknown])
        await task.value
        #expect(!model.isLoading)
        #expect(model.visibleRooms(query: "").map(\.id) == ["available", "unknown", "unknown-explicit", "unavailable"])
        #expect(model.availability(for: "available") == .available)
        #expect(model.availability(for: "unavailable") == .unavailable)
        #expect(model.availability(for: "unknown-explicit") == .unknown)
        #expect(model.availability["unknown"] == nil)
        #expect(model.availability(for: "unknown") == .unknown)
        #expect(model.visibleRooms(query: "  gAmMa ").map(\.id) == ["available"])
    }

    @Test
    func availabilityArrivingBeforeRoomObservationIsRetained() async {
        let service = RoomsStub()
        service.rooms = [room("room", "Meeting room")]
        service.availabilityHandler = { _ in ["room": .available] }
        let model = makeModel(rooms: service)
        await model.loadAvailability(for: request())
        await model.observeRooms(calendarId: "calendar")

        #expect(model.availability == ["room": .available])
        #expect(model.rooms.count == 1)
    }

    @Test
    func clearingAccountClearsRoomsAndAvailability() async {
        let service = RoomsStub()
        service.rooms = [room("room", "Meeting room")]
        service.availabilityHandler = { _ in ["room": .unavailable] }
        let model = makeModel(rooms: service)
        await model.observeRooms(calendarId: "calendar")
        await model.loadAvailability(for: request())
        #expect(model.availability(for: "room") == .unavailable)

        await model.observeRooms(calendarId: nil)
        await model.loadAvailability(for: nil)
        #expect(model.rooms.isEmpty)
        #expect(model.availability.isEmpty)
        #expect(!model.isLoading)
    }

    @Test
    func failedAvailabilityClearsPreviousStatuses() async {
        let service = RoomsStub()
        service.rooms = [room("room", "Meeting room")]
        service.availabilityHandler = { _ in ["room": .available] }
        let model = makeModel(rooms: service)
        await model.observeRooms(calendarId: "calendar")
        await model.loadAvailability(for: request())
        #expect(model.availability(for: "room") == .available)

        service.availabilityHandler = { _ in throw StubError.failed }
        let updatedDraft = EventDraft(
            startDate: Date(timeIntervalSince1970: 2000),
            endDate: Date(timeIntervalSince1970: 5600)
        )
        await model.loadAvailability(for: request(draft: updatedDraft))

        #expect(model.rooms.count == 1)
        #expect(model.availability.isEmpty)
        #expect(model.availability(for: "room") == .unknown)
        #expect(!model.isLoading)
        #expect(service.availabilityCalls == 2)
    }

    @Test
    func staleAvailabilityCannotOverwriteNewContext() async {
        let service = RoomsStub()
        let started = Gate<Bool>()
        let response = Gate<[String: MeetingRoomAvailability]>()
        service.availabilityHandler = { request in
            if request.calendarId == "calendar" {
                started.open(true)
                return await response.wait()
            }
            return ["new": .available]
        }
        let model = makeModel(rooms: service)
        let oldTask = Task { await model.loadAvailability(for: request()) }
        _ = await started.wait()
        await model.loadAvailability(for: request(calendarId: "other"))
        response.open(["old": .unavailable])
        await oldTask.value

        #expect(model.availability == ["new": .available])
    }

    @Test
    func searchClearsEmptyInputAndFailedSearchFinishesWithoutInventingResults() async {
        let places = PlacesStub()
        places.handler = { query in
            #expect(query == "Geneva")
            return [place("Geneva")]
        }
        let model = makeModel(places: places)
        await model.searchPlaces(query: "  Geneva ")
        #expect(model.places == [place("Geneva")])
        #expect(!model.isLoading)

        await model.searchPlaces(query: "  ")
        #expect(model.places.isEmpty)
        #expect(!model.isLoading)
        #expect(places.queries == ["Geneva"])

        places.handler = { _ in throw StubError.failed }
        await model.searchPlaces(query: "Geneva")
        #expect(model.places.isEmpty)
        #expect(!model.isLoading)
    }

    @Test
    func staleSearchAndCancelledResponsesAreIgnored() async {
        let places = PlacesStub()
        let started = Gate<Bool>()
        let response = Gate<[LocationPlace]>()
        places.handler = { query in
            if query == "old" {
                started.open(true)
                return await response.wait()
            }
            return [place("new")]
        }
        let model = makeModel(places: places)
        let oldTask = Task { await model.searchPlaces(query: "old") }
        _ = await started.wait()
        #expect(model.isLoading)
        oldTask.cancel()
        await model.searchPlaces(query: "new")
        response.open([place("old")])
        await oldTask.value

        #expect(model.places == [place("new")])
        #expect(!model.isLoading)
    }

    @Test
    func roomLoadingFinishesWhenRoomsAreEmitted() async {
        let service = RoomsStub()
        let started = Gate<Bool>()
        let response = Gate<Bool>()
        let emitted = Gate<Void>()
        let finishObservation = Gate<Void>()
        service.beforeObservation = {
            started.open(true)
            _ = await response.wait()
        }
        service.afterObservation = {
            emitted.open(())
            await finishObservation.wait()
        }
        let model = makeModel(rooms: service)
        let task = Task { await model.observeRooms(calendarId: "calendar") }
        _ = await started.wait()
        #expect(model.isLoading)

        response.open(true)
        await emitted.wait()
        #expect(!model.isLoading)
        finishObservation.open(())
        await task.value
    }

    @Test
    func availabilityRequestUsesSelectedCalendarAndDraftContext() async throws {
        let model = EventFormViewModel(editionMode: .new(selectedDate: .now))
        let calendar = UICalendar(
            id: "selected", displayName: "Calendar", colorArgb: 0,
            accountId: 84, isVisible: true, accessLevel: .owner
        )
        await model.updateCalendarSections([UICalendarSection(
            accountId: 84,
            organisationId: nil,
            organisationName: nil,
            calendars: [calendar]
        )])
        let request = try #require(model.locationAvailabilityRequest)
        #expect(request.calendarId == "selected")
        #expect(request.start == model.draft.startDate)
        #expect(request.end == model.draft.endDate)
        #expect(request.startTimeZone == model.draft.startTimeZone)
    }

    private func room(_ id: String, _ name: String) -> LocationRoom {
        LocationRoom(id: id, name: name, capacity: 20, floor: 3)
    }

    private func place(_ name: String) -> LocationPlace {
        LocationPlace(id: name, name: name, address: "")
    }

    private func request(calendarId: String = "calendar", draft: EventDraft? = nil) -> LocationAvailabilityRequest {
        LocationAvailabilityRequest(
            calendarId: calendarId,
            draft: draft ?? EventDraft(startDate: Date(timeIntervalSince1970: 1000), endDate: Date(timeIntervalSince1970: 4600))
        )
    }

    private func makeModel(
        rooms: RoomsStub? = nil,
        places: PlacesStub? = nil
    ) -> LocationPickerViewModel {
        LocationPickerViewModel(roomsService: rooms ?? RoomsStub(), placesService: places ?? PlacesStub(), searchDelay: .zero)
    }
}

@MainActor
private final class RoomsStub: LocationRoomsProviding {
    var rooms = [LocationRoom]()
    var observedCalendarIds = [String]()
    var availabilityCalls = 0
    var beforeObservation: (() async -> Void)?
    var afterObservation: (() async -> Void)?
    var availabilityHandler: (LocationAvailabilityRequest) async throws -> [String: MeetingRoomAvailability] = { _ in [:] }

    func observeRooms(calendarId: String, onUpdate: @MainActor ([LocationRoom]) -> Void) async {
        observedCalendarIds.append(calendarId)
        await beforeObservation?()
        onUpdate(rooms)
        await afterObservation?()
    }

    func availability(for request: LocationAvailabilityRequest) async throws -> [String: MeetingRoomAvailability] {
        availabilityCalls += 1
        return try await availabilityHandler(request)
    }
}

@MainActor
private final class PlacesStub: LocationPlacesSearching {
    var queries = [String]()
    var handler: (String) async throws -> [LocationPlace] = { _ in [] }

    func search(query: String) async throws -> [LocationPlace] {
        queries.append(query)
        return try await handler(query)
    }
}

@MainActor
private final class Gate<Value> {
    private var value: Value?
    private var continuation: CheckedContinuation<Value, Never>?

    func wait() async -> Value {
        if let value { return value }
        return await withCheckedContinuation { continuation = $0 }
    }

    func open(_ value: Value) {
        self.value = value
        continuation?.resume(returning: value)
        continuation = nil
    }
}

private enum StubError: Error {
    case failed
}
