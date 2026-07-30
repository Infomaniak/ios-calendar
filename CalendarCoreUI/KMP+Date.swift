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
@preconcurrency import MultiplatformCalendar
import SwiftUI

public extension Date {
    var kotlinDate: Kotlinx_datetimeLocalDateTime {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: self
        )

        return .init(
            year: Int32(components.year ?? 0),
            month: Int32(components.month ?? 0),
            day: Int32(components.day ?? 0),
            hour: Int32(components.hour ?? 0),
            minute: Int32(components.minute ?? 0),
            second: Int32(components.second ?? 0),
            nanosecond: Int32(components.nanosecond ?? 0)
        )
    }
}
