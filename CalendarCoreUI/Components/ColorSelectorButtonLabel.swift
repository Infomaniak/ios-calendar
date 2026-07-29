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

import CalendarResources
import SwiftUI

public struct ColorSelectorButtonLabel: View {
    @Binding private var color: Color
    @Binding private var calendarColor: Color

    public init(
        color: Binding<Color> = .constant(.gray),
        calendarColor: Binding<Color> = .constant(.gray)
    ) {
        _color = color
        _calendarColor = calendarColor
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 18, height: 18)
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 0)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(calendarColor, lineWidth: 3)
                    .frame(width: 28, height: 28)
            }
            .padding(.trailing, 8)
    }
}
