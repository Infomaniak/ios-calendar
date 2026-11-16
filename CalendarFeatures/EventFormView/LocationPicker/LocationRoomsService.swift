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

struct LocationAvailabilityRequest: Hashable {
    let calendarId: String
    let start: Date
    let end: Date
    let startTimeZone: Foundation.TimeZone?
    let endTimeZone: Foundation.TimeZone?
    let allDay: Bool

    init(calendarId: String, draft: EventDraft) {
        self.calendarId = calendarId
        start = draft.startDate
        end = draft.endDate
        startTimeZone = draft.startTimeZone
        endTimeZone = draft.endTimeZone
        allDay = draft.allDay
    }

    func timing() throws -> EventTiming {
        try EventDraft(
            calendarId: calendarId,
            allDay: allDay,
            startDate: start,
            startTimeZone: startTimeZone,
            endDate: end,
            endTimeZone: endTimeZone
        ).sdkTiming()
    }
}

protocol LocationRoomsProviding: Sendable {
    func observeRooms(calendarId: String, onUpdate: @MainActor ([LocationRoom]) -> Void) async
    func availability(for request: LocationAvailabilityRequest) async throws -> [String: MeetingRoomAvailability]
}

struct LocationRoomsService: LocationRoomsProviding {
    func observeRooms(calendarId: String, onUpdate: @MainActor ([LocationRoom]) -> Void) async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await resources in calendarSDK.calendarBookableResourcesManager.observeResources(calendarId: calendarId) {
            guard !Task.isCancelled else { return }
            await onUpdate(resources.map { LocationRoom(resource: $0) })
        }
    }

    func availability(for request: LocationAvailabilityRequest) async throws -> [String: MeetingRoomAvailability] {
        @InjectService var calendarSDK: CalendarCoreGraph
        let values = try await calendarSDK.calendarBookableResourcesManager.availabilityValues(
            calendarId: request.calendarId,
            timing: request.timing(),
            timeZone: (request.startTimeZone ?? .current).toKotlinTimeZone()
        )
        return values.mapValues { MeetingRoomAvailability(isAvailable: $0.boolValue) }
    }
}
