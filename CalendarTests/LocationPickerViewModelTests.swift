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
        #expect(place.location == .place(name: expected))
        #expect(place.location.stringValue == expected)
    }

    @Test
    func roomsRenderBeforeAvailabilityAndSortAsStatusesArrive() async {
        let service = RoomsStub()
        service.rooms = [
            room("unavailable", "Alpha"),
            room("unknown", "Beta"),
            room("available", "Gamma")
        ]
        let started = Gate<Bool>()
        let response = Gate<[String: Bool]>()
        service.availabilityHandler = { _ in
            started.open(true)
            return await response.wait()
        }
        let model = makeModel(rooms: service)
        await model.observeRooms(accountId: 42)
        let task = Task { await model.loadAvailability(for: request()) }
        _ = await started.wait()

        #expect(service.observedAccountIds == [42])
        #expect(model.rooms.count == 3)
        #expect(model.availability.isEmpty)
        #expect(model.isLoading)
        #expect(model.visibleRooms(query: "").map(\.id) == ["unavailable", "unknown", "available"])

        response.open(["available": true, "unavailable": false])
        await task.value
        #expect(!model.isLoading)
        #expect(model.visibleRooms(query: "").map(\.id) == ["available", "unknown", "unavailable"])
        #expect(model.availability["unknown"] == nil)
        #expect(model.visibleRooms(query: "  gAmMa ").map(\.id) == ["available"])
    }

    @Test
    func availabilityArrivingBeforeRoomObservationIsRetained() async {
        let service = RoomsStub()
        service.rooms = [room("room", "Meeting room")]
        service.availabilityHandler = { _ in ["room": true] }
        let model = makeModel(rooms: service)
        await model.loadAvailability(for: request())
        await model.observeRooms(accountId: 42)

        #expect(model.availability == ["room": true])
        #expect(model.rooms.count == 1)
    }

    @Test
    func unavailableRoomsRemainSelectableAndAccountChangeClearsRoomMetadata() async {
        let service = RoomsStub()
        let room = room("room", "Meeting room")
        service.rooms = [room]
        service.availabilityHandler = { _ in ["room": false] }
        let model = makeModel(rooms: service)
        await model.observeRooms(accountId: 42)
        await model.loadAvailability(for: request())
        let selected = room.location
        #expect(selected == .room(id: "room", name: "Meeting room", accountId: 42))
        #expect(model.availability[room.id] == false)

        await model.observeRooms(accountId: nil)
        await model.loadAvailability(for: nil)
        #expect(selected.stringValue == "Meeting room")
        #expect(model.rooms.isEmpty)
        #expect(model.availability.isEmpty)
        #expect(!model.isLoading)
    }

    @Test
    func failedAvailabilityLeavesRoomsVisibleWithUnknownStatus() async {
        let service = RoomsStub()
        service.rooms = [room("room", "Meeting room")]
        service.availabilityHandler = { _ in throw StubError.failed }
        let model = makeModel(rooms: service)
        await model.observeRooms(accountId: 42)
        await model.loadAvailability(for: request())

        #expect(model.rooms.count == 1)
        #expect(model.visibleRooms(query: "") == service.rooms)
        #expect(model.availability.isEmpty)
        #expect(!model.isLoading)
        #expect(service.availabilityCalls == 1)
        #expect(service.rooms[0].location == .room(id: "room", name: "Meeting room", accountId: 42))
    }

    @Test
    func failedAvailabilityClearsPreviousStatuses() async {
        let service = RoomsStub()
        service.rooms = [room("room", "Meeting room")]
        service.availabilityHandler = { _ in ["room": true] }
        let model = makeModel(rooms: service)
        await model.observeRooms(accountId: 42)
        await model.loadAvailability(for: request())
        #expect(model.availability["room"] == true)

        service.availabilityHandler = { _ in throw StubError.failed }
        let updatedDraft = EventDraft(
            startDate: Date(timeIntervalSince1970: 2000),
            endDate: Date(timeIntervalSince1970: 5600)
        )
        await model.loadAvailability(for: request(draft: updatedDraft))

        #expect(model.rooms.count == 1)
        #expect(model.availability.isEmpty)
        #expect(!model.isLoading)
        #expect(service.availabilityCalls == 2)
    }

    @Test
    func staleAvailabilityCannotOverwriteNewContext() async {
        let service = RoomsStub()
        let started = Gate<Bool>()
        let response = Gate<[String: Bool]>()
        service.availabilityHandler = { request in
            if request.accountId == 42 {
                started.open(true)
                return await response.wait()
            }
            return ["new": true]
        }
        let model = makeModel(rooms: service)
        let oldTask = Task { await model.loadAvailability(for: request()) }
        _ = await started.wait()
        await model.loadAvailability(for: request(accountId: 84))
        response.open(["old": false])
        await oldTask.value

        #expect(model.availability == ["new": true])
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

    @Test(arguments: [
        [LoadingOperation.rooms, .availability, .search],
        [.rooms, .search, .availability],
        [.availability, .rooms, .search],
        [.availability, .search, .rooms],
        [.search, .rooms, .availability],
        [.search, .availability, .rooms]
    ])
    func loadingRemainsVisibleUntilAllOverlappingOperationsFinish(order: [LoadingOperation]) async {
        let roomsService = RoomsStub()
        let placesService = PlacesStub()
        let roomsStarted = Gate<Void>()
        let roomsResponse = Gate<Void>()
        let availabilityStarted = Gate<Void>()
        let availabilityResponse = Gate<Void>()
        let searchStarted = Gate<Void>()
        let searchResponse = Gate<Void>()
        roomsService.beforeObservation = {
            roomsStarted.open(())
            await roomsResponse.wait()
        }
        roomsService.availabilityHandler = { _ in
            availabilityStarted.open(())
            await availabilityResponse.wait()
            return [:]
        }
        placesService.handler = { _ in
            searchStarted.open(())
            await searchResponse.wait()
            return []
        }
        let model = makeModel(rooms: roomsService, places: placesService)
        let roomsTask = Task { await model.observeRooms(accountId: 42) }
        let availabilityTask = Task { await model.loadAvailability(for: request()) }
        let searchTask = Task { await model.searchPlaces(query: "Place") }
        await roomsStarted.wait()
        await availabilityStarted.wait()
        await searchStarted.wait()
        #expect(model.isLoading)

        for (index, operation) in order.enumerated() {
            switch operation {
            case .rooms:
                roomsResponse.open(())
                await roomsTask.value
            case .availability:
                availabilityResponse.open(())
                await availabilityTask.value
            case .search:
                searchResponse.open(())
                await searchTask.value
            }
            #expect(model.isLoading == (index < order.count - 1))
        }
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
        let task = Task { await model.observeRooms(accountId: 42) }
        _ = await started.wait()
        #expect(model.isLoading)

        response.open(true)
        await emitted.wait()
        #expect(!model.isLoading)
        finishObservation.open(())
        await task.value
    }

    @Test
    func availabilityRequestUsesSelectedCalendarAccountAndDraftContext() throws {
        let model = EventFormViewModel(editionMode: .new(selectedDate: .now), userDefaults: .shared)
        let calendar = UICalendar(
            id: "selected", displayName: "Calendar", colorArgb: 0,
            accountId: 84, isVisible: true, accessLevel: .owner
        )
        model.updateAvailableCalendars([calendar])
        model.draft.availabilityRRule = "FREQ=WEEKLY"
        let request = try #require(model.locationAvailabilityRequest)
        #expect(request.accountId == 84)
        #expect(request.start == model.draft.startDate)
        #expect(request.end == model.draft.endDate)
        #expect(request.startTimeZone == model.draft.startTimeZone)
        #expect(request.rrule == "FREQ=WEEKLY")
    }

    @Test(arguments: [true, false])
    func availabilityRequestPreservesDraftTiming(allDay: Bool) throws {
        let optionalZone = Foundation.TimeZone(identifier: "Europe/Zurich")
        let zone = try #require(optionalZone)
        let draft = EventDraft(
            calendarId: "calendar",
            allDay: allDay,
            startDate: Date(timeIntervalSince1970: 1_793_347_200),
            startTimeZone: allDay ? zone : nil,
            endDate: Date(timeIntervalSince1970: 1_793_433_600),
            endTimeZone: allDay ? zone : nil
        )
        let request = request(draft: draft)
        #expect(request.start == draft.startDate)
        #expect(request.end == draft.endDate)
        #expect(request.startTimeZone == draft.startTimeZone)
        #expect(request.endTimeZone == draft.endTimeZone)
        #expect(request.allDay == draft.allDay)
    }

    private func room(_ id: String, _ name: String) -> LocationRoom {
        LocationRoom(id: id, name: name, capacity: 20, floor: 3, accountId: 42)
    }

    private func place(_ name: String) -> LocationPlace {
        LocationPlace(id: name, name: name, address: "")
    }

    private func request(accountId: Int64 = 42, draft: EventDraft? = nil) -> LocationAvailabilityRequest {
        LocationAvailabilityRequest(
            accountId: accountId,
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
    var observedAccountIds = [Int64]()
    var availabilityCalls = 0
    var beforeObservation: (() async -> Void)?
    var afterObservation: (() async -> Void)?
    var availabilityHandler: (LocationAvailabilityRequest) async throws -> [String: Bool] = { _ in [:] }

    func observeRooms(accountId: Int64, onUpdate: @MainActor ([LocationRoom]) -> Void) async {
        observedAccountIds.append(accountId)
        await beforeObservation?()
        onUpdate(rooms)
        await afterObservation?()
    }

    func availability(for request: LocationAvailabilityRequest) async throws -> [String: Bool] {
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

enum LoadingOperation {
    case rooms
    case availability
    case search
}
