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

import Foundation
import MultiplatformCalendar

public struct EventDraft: Equatable, Sendable {
    public var calendarId: String?

    public var title: String
    public var description: String

    public var allDay: Bool
    public var startDate: Date
    public var startTimeZone: TimeZone?
    public var endDate: Date
    public var endTimeZone: TimeZone?

    public var attendees: [Attendee]

    public var isOccupied: Bool
    public var isPrivate: Bool

    public init(
        calendarId: String? = nil,
        title: String = "",
        description: String = "",
        allDay: Bool = false,
        startDate: Date,
        startTimeZone: TimeZone? = .current,
        endDate: Date,
        endTimeZone: TimeZone? = .current,
        attendees: [Attendee] = [],
        isOccupied: Bool = true,
        isPrivate: Bool = false
    ) {
        self.calendarId = calendarId
        self.title = title
        self.description = description
        self.allDay = allDay
        self.startDate = startDate
        self.startTimeZone = startTimeZone
        self.endDate = endDate
        self.endTimeZone = endTimeZone
        self.attendees = attendees
        self.isOccupied = isOccupied
        self.isPrivate = isPrivate
    }
}

public extension EventDraft {
    static func empty() -> EventDraft {
        let startDate = Date()

        return EventDraft(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(UserDefaults.shared.defaultEventDuration.timeInterval)
        )
    }

    func toEventEditData(preserving originalData: EventEditData? = nil) throws -> EventEditData {
        guard let calendarId, !calendarId.isEmpty else {
            throw EventDraftValidator.ValidationError.missingCalendar
        }

        return try EventEditData(
            title: title,
            timing: sdkTiming(recurrenceRule: originalData?.timing.recurrenceRule),
            location: originalData?.location,
            description: description,
            calendarId: calendarId,
            eventColor: originalData?.eventColor,
            alarms: originalData?.alarms ?? []
        )
    }

    private func sdkTiming(recurrenceRule: RecurrenceRule?) throws -> EventTiming {
        let startZone = Kotlinx_datetimeTimeZone.companion.of(zoneId: (startTimeZone ?? .current).identifier)
        let endZone = Kotlinx_datetimeTimeZone.companion.of(zoneId: (endTimeZone ?? .current).identifier)
        return try EventTiming(
            start: localDateTime(startDate, in: startZone),
            end: localDateTime(endDate, in: endZone),
            startTimeZone: allDay || startTimeZone == nil ? nil : startZone,
            endTimeZone: allDay || endTimeZone == nil ? nil : endZone,
            isAllDay: allDay,
            recurrenceRule: recurrenceRule
        )
    }

    private func localDateTime(_ date: Date, in timeZone: Kotlinx_datetimeTimeZone) throws -> Kotlinx_datetimeLocalDateTime {
        guard let milliseconds = Int64(exactly: (date.timeIntervalSince1970 * 1000).rounded(.towardZero)) else {
            throw EventDraftValidator.ValidationError.invalidDates
        }
        let instant = KotlinInstant.companion.fromEpochMilliseconds(epochMilliseconds: milliseconds)
        let local = timeZone.toLocalDateTime(instant)
        guard allDay else { return local }
        return Kotlinx_datetimeLocalDateTime(
            year: local.year,
            month: local.month,
            day: local.day,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0
        )
    }
}

private extension EventDraft {
    struct AttendeeSnapshot: Equatable {
        let email: String
        let displayName: String?
        let status: ParticipationStatus
        let role: AttendeeRole
        let isOrganizer: Bool
        let responseNeeded: Bool

        init(_ attendee: Attendee) {
            email = attendee.email
            displayName = attendee.displayName
            status = attendee.status
            role = attendee.role
            isOrganizer = attendee.isOrganizer
            responseNeeded = attendee.responseNeeded
        }

        var sdkValue: Attendee {
            Attendee(
                email: email,
                displayName: displayName,
                status: status,
                role: role,
                isOrganizer: isOrganizer,
                responseNeeded: responseNeeded
            )
        }
    }
}
