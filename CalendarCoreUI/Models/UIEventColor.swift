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

public struct UIEventColor: Sendable, Equatable, Hashable {
    public let calendarSourceColor: Color
    public let sourceColor: Color
    public let containerColor: Color
    public let onContainerColor: Color
    public let containerVariantColor: Color
    public let onContainerVariantColor: Color

    public let sourceColorArgb: Int32

    public init(
        calendarSourceColor: Color,
        sourceColor: Color,
        containerColor: Color,
        onContainerColor: Color,
        containerVariantColor: Color,
        onContainerVariantColor: Color
    ) {
        self.sourceColor = sourceColor
        self.calendarSourceColor = calendarSourceColor
        self.containerColor = containerColor
        self.onContainerColor = onContainerColor
        self.containerVariantColor = containerVariantColor
        self.onContainerVariantColor = onContainerVariantColor
        sourceColorArgb = sourceColor.cgColor?.argb ?? 0
    }

    public init(eventColors: EventColors) {
        sourceColor = Color(argb: eventColors.sourceColor)
        calendarSourceColor = Color(argb: eventColors.calendarSourceColor)
        containerColor = Color(argb: eventColors.containerColor)
        onContainerColor = Color(eventColor: eventColors.onContainerColor)
        containerVariantColor = Color(argb: eventColors.containerVariantColor)
        onContainerVariantColor = Color(eventColor: eventColors.onContainerVariantColor)
        sourceColorArgb = eventColors.sourceColor
    }

    public static func == (lhs: UIEventColor, rhs: UIEventColor) -> Bool {
        lhs.sourceColorArgb == rhs.sourceColorArgb
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sourceColorArgb)
    }
}

public extension UIEventColor {
    static let preview = UIEventColor(
        calendarSourceColor: Color.green,
        sourceColor: Color.orange,
        containerColor: Color.orange.opacity(0.2),
        onContainerColor: Color(red: 1, green: 0.2, blue: 0),
        containerVariantColor: Color.orange.opacity(0.1),
        onContainerVariantColor: Color(red: 1, green: 0.2, blue: 0)
    )
}
