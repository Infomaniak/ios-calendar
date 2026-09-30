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
import CalendarResources
import ESDSSymbols
import Foundation

public extension EventAlarmDraft {
    var label: String {
        guard let trigger else { return AlarmOffset.none.label }
        switch trigger {
        case .relative(offset: 0, relatedTo: .start):
            return CalendarResourcesStrings.alarmOffsetAtTimeOfEvent
        case .relative(let offset, _):
            let duration = Duration.seconds(abs(offset))
                .formatted(.units(allowed: [.days, .hours, .minutes], width: .wide, maximumUnitCount: 2))
            return offset < 0
                ? CalendarResourcesStrings.alarmOffsetCustomBefore(duration)
                : CalendarResourcesStrings.alarmOffsetCustomAfter(duration)
        case .absolute(let date):
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

public extension EventAlarmDraft {
    static let preview = EventAlarmDraft(
        action: .display,
        trigger: .relative(offset: -300, relatedTo: .start),
        attachments: [],
        attendees: ["tim@apple.com"],
        description: "Reminder: standup meeting",
        summary: "Daily Standup"
    )

    static let previews: [EventAlarmDraft] = [
        EventAlarmDraft(action: .display, trigger: .relative(offset: -300, relatedTo: .start),
                        attachments: [], attendees: ["tim@apple.com"],
                        description: "5 minutes before", summary: "Quick reminder"),
        EventAlarmDraft(action: .email, trigger: .relative(offset: -3600, relatedTo: .end),
                        attachments: [], attendees: ["john@apple.com"],
                        description: "1 hour after", summary: "Prepare slides")
    ]
}

public extension UIAlarmAction {
    var label: String {
        switch self {
        case .display:
            return CalendarResourcesStrings.notificationTypePush
        case .audio, .unknown:
            return CalendarResourcesStrings.notificationTypeOther
        case .email:
            return CalendarResourcesStrings.notificationTypeEmail
        }
    }

    var icon: ESDSSymbols {
        switch self {
        case .display:
            return .bubbleTopRightCircle
        case .audio:
            return .bell
        default:
            return .bell
        }
    }
}

public extension AlarmOffset {
    var label: String {
        switch self {
        case .none:
            return CalendarResourcesStrings.alarmOffsetNone
        case .atTimeOfEvent:
            return CalendarResourcesStrings.alarmOffsetAtTimeOfEvent
        default:
            return EventAlarmDraft(offset: self).label
        }
    }
}
