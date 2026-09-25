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
import MultiplatformCalendar

public extension EventDraft {
    var classification: UIClassification {
        return isPrivate ? .private : .public
    }

    static func fromEvent(_ event: UIEvent, editData: EventEditData) -> EventDraft {
        let timing = UITiming(eventTiming: editData.timing)
        return EventDraft(
            calendarId: event.calendarId,
            title: editData.title,
            description: editData.description_ ?? "",
            allDay: editData.timing.isAllDay,
            startDate: timing.start,
            startTimeZone: timing.startTimeZone,
            endDate: timing.end,
            endTimeZone: timing.endTimeZone,
            attendees: event.attendees.map {
                Attendee(
                    email: $0.email,
                    displayName: $0.displayName,
                    status: $0.status.sdkValue,
                    role: .requested,
                    isOrganizer: $0.isOrganizer,
                    responseNeeded: false
                )
            },
            isOccupied: editData.timeBlocking != .doesNotBlock,
            isPrivate: event.classification == .private
        )
    }
}

private extension UIParticipationStatus {
    var sdkValue: ParticipationStatus {
        switch self {
        case .accepted:
            return .accepted
        case .declined:
            return .declined
        case .tentative:
            return .tentative
        case .needsAction:
            return .needsAction
        }
    }
}
