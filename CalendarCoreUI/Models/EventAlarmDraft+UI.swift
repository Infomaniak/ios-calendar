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
        return trigger.label
    }
}

public extension UIAlarmTrigger {
    var label: String {
        switch self {
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
        case .email:
            return .envelope
        case .audio, .unknown:
            return .bell
        }
    }
}

public extension AlarmOffset {
    var label: String {
        return trigger.label
    }
}
