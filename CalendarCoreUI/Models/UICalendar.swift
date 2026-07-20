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
import SwiftUI

public struct UICalendar: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let color: Color
    public let accountId: Int
    public let isVisible: Bool

    public init(id: String, displayName: String, color: Color, accountId: Int, isVisible: Bool) {
        self.id = id
        self.displayName = displayName
        self.color = color
        self.accountId = accountId
        self.isVisible = isVisible
    }
}

public extension UICalendar {
    init(calendar: MultiplatformCalendar.Calendar) {
        id = calendar.idValue
        displayName = calendar.displayName
        color = Color(argb: calendar.colors.calendarSourceColor)
        accountId = Int(calendar.accountIdValue)
        isVisible = calendar.isVisible
    }
}

public extension UICalendar {
    static let preview = UICalendar(id: "0", displayName: "John Appleseed - Personal", color: .red, accountId: 1, isVisible: true)
}
