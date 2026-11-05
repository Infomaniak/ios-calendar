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
import InfomaniakDI
@preconcurrency import MultiplatformCalendar

struct LocationRoom: Identifiable, Equatable {
    let id: String
    let name: String
    let capacity: Int?
    let floor: Int?
    let accountId: Int64

    var location: EventLocation {
        .room(id: id, name: name, accountId: accountId)
    }
}

struct LocationAvailabilityRequest: Hashable {
    let accountId: Int64
    let start: Date
    let end: Date
    let startTimeZone: Foundation.TimeZone?
    // periphery:ignore - Used for Hashable
    let endTimeZone: Foundation.TimeZone?
    // periphery:ignore - Used for Hashable
    let allDay: Bool
    let rrule: String?

    init(accountId: Int64, draft: EventDraft) {
        self.accountId = accountId
        start = draft.startDate
        end = draft.endDate
        startTimeZone = draft.startTimeZone
        endTimeZone = draft.endTimeZone
        allDay = draft.allDay
        rrule = draft.availabilityRRule
    }
}

protocol LocationRoomsProviding: Sendable {
    func observeRooms(accountId: Int64, onUpdate: @MainActor ([LocationRoom]) -> Void) async
    func availability(for request: LocationAvailabilityRequest) async throws -> [String: MeetingRoomAvailability]
}

struct LocationRoomsService: LocationRoomsProviding {
    func observeRooms(accountId: Int64, onUpdate: @MainActor ([LocationRoom]) -> Void) async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await resources in calendarSDK.bookableResourcesManager.observeResources(accountId: accountId) {
            guard !Task.isCancelled else { return }
            await onUpdate(resources.map { resource in
                LocationRoom(
                    id: resource.uuidValue,
                    name: resource.name,
                    capacity: resource.capacity?.intValue,
                    floor: resource.floor?.intValue,
                    accountId: accountId
                )
            })
        }
    }

    func availability(for request: LocationAvailabilityRequest) async throws -> [String: MeetingRoomAvailability] {
        @InjectService var calendarSDK: CalendarCoreGraph
        let values = try await calendarSDK.bookableResourcesManager.availabilityValues(
            accountId: request.accountId,
            start: request.start.instant,
            end: request.end.instant,
            timeZone: (request.startTimeZone ?? .current).toKotlinTimeZone(),
            rrule: request.rrule
        )
        return values.mapValues { MeetingRoomAvailability(isAvailable: $0.boolValue) }
    }
}
