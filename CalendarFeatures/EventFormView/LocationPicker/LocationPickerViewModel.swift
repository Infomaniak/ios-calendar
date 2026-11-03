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
import Foundation
import Observation
import OSLog

@MainActor @Observable
final class LocationPickerViewModel {
    private static let logger = Logger(category: "LocationPicker")

    private(set) var rooms = [LocationRoom]()
    private(set) var availability = [String: MeetingRoomAvailability]()
    private(set) var places = [LocationPlace]()
    private var isSearching = false
    private var isLoadingRooms = false
    private var isLoadingAvailability = false

    private var accountId: Int64?
    private var availabilityRequest: LocationAvailabilityRequest?
    private var searchQuery = ""
    private let roomsService: any LocationRoomsProviding
    private let placesService: any LocationPlacesSearching
    private let searchDelay: Duration

    var isLoading: Bool {
        isSearching || isLoadingRooms || isLoadingAvailability
    }

    init(
        roomsService: any LocationRoomsProviding = LocationRoomsService(),
        placesService: any LocationPlacesSearching = LocationPlacesService(),
        searchDelay: Duration = .milliseconds(300)
    ) {
        self.roomsService = roomsService
        self.placesService = placesService
        self.searchDelay = searchDelay
    }

    func availability(for roomId: String) -> MeetingRoomAvailability {
        availability[roomId] ?? .unknown
    }

    func visibleRooms(query: String) -> [LocationRoom] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return rooms
            .filter { query.isEmpty || $0.name.localizedStandardContains(query) }
            .sorted {
                let firstRank = availabilityRank($0.id)
                let secondRank = availabilityRank($1.id)
                if firstRank != secondRank {
                    return firstRank < secondRank
                }
                let comparison = $0.name.localizedStandardCompare($1.name)
                return comparison == .orderedSame ? $0.id < $1.id : comparison == .orderedAscending
            }
    }

    func observeRooms(accountId: Int64?) async {
        if self.accountId != accountId {
            rooms = []
            if availabilityRequest?.accountId != accountId {
                availability = [:]
            }
        }
        self.accountId = accountId
        isLoadingRooms = accountId != nil
        guard let accountId else { return }
        await roomsService.observeRooms(accountId: accountId) { rooms in
            guard !Task.isCancelled, self.accountId == accountId else { return }
            self.rooms = rooms
            self.isLoadingRooms = false
        }
    }

    func loadAvailability(for request: LocationAvailabilityRequest?) async {
        availabilityRequest = request
        availability = [:]
        isLoadingAvailability = request != nil
        guard let request else { return }
        do {
            let values = try await roomsService.availability(for: request)
            guard !Task.isCancelled, availabilityRequest == request else { return }
            availability = values
            isLoadingAvailability = false
        } catch {
            guard !Task.isCancelled, availabilityRequest == request else { return }
            isLoadingAvailability = false
            Self.logger.error("Unable to load room availability")
        }
    }

    func searchPlaces(query: String) async {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchQuery = query
        places = []
        isSearching = !query.isEmpty
        guard !query.isEmpty else { return }
        do {
            try await Task.sleep(for: searchDelay)
            let places = try await placesService.search(query: query)
            guard !Task.isCancelled, searchQuery == query else { return }
            self.places = places
            isSearching = false
        } catch {
            guard !Task.isCancelled, searchQuery == query else { return }
            isSearching = false
            Self.logger.error("Unable to search for places")
        }
    }

    private func availabilityRank(_ id: String) -> Int {
        switch availability(for: id) {
        case .available: 0
        case .unknown: 1
        case .unavailable: 2
        }
    }
}
