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

import MultiplatformCalendar

public enum UICalendarNotificationState: Hashable, Sendable {
    case enabled
    case disabled
    case custom(topics: Set<NotificationTopic>)
}

public extension UICalendarNotificationState {
    init(state: CalendarNotificationState) {
        switch onEnum(of: state) {
        case .enabled:
            self = .enabled
        case .disabled:
            self = .disabled
        case .custom(let custom):
            self = .custom(topics: custom.topics)
        }
    }

    var sdkValue: CalendarNotificationState {
        switch self {
        case .enabled:
            return CalendarNotificationStateEnabled.shared
        case .disabled:
            return CalendarNotificationStateDisabled.shared
        case .custom(let topics):
            return CalendarNotificationStateCustom(topics: topics)
        }
    }
}
