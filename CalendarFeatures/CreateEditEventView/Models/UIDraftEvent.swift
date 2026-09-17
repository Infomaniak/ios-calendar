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

import CalendarCoreUI
import Foundation

public struct UIDraftEvent: Equatable {
    var calendar: UICalendar?

    var title: String

    var allDay: Bool
    var startDate: Date
    var startTimeZone: TimeZone
    var endDate: Date
    var endTimeZone: TimeZone

    var attendees: [UIAttendee]

    var isOccupied: Bool
    var isPrivate: Bool

    var classification: UIClassification {
        return isPrivate ? .private : .public
    }
}

public extension UIDraftEvent {
    static func empty() -> UIDraftEvent {
        return UIDraftEvent(
            calendar: nil,
            title: "",
            allDay: false,
            startDate: Date(),
            startTimeZone: TimeZone.current,
            endDate: Date().addingTimeInterval(60 * 60), // TODO: Use UserDefaults
            endTimeZone: TimeZone.current,
            attendees: [],
            isOccupied: true,
            isPrivate: false
        )
    }

    static func fromEvent(_ event: CalendarCoreUI.UIEvent, calendar: UICalendar) -> UIDraftEvent {
        return UIDraftEvent(
            calendar: calendar,
            title: event.title,
            allDay: event.isAllDay,
            startDate: event.timing.start,
            startTimeZone: event.timing.startTimeZone ?? TimeZone.current,
            endDate: event.timing.end,
            endTimeZone: event.timing.endTimeZone ?? TimeZone.current,
            attendees: event.attendees,
            isOccupied: false,
            isPrivate: false
        )
    }
}
