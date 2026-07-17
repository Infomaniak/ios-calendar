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

import DesignSystem
import ESDSFoundation
import SwiftUI
import UIKit

struct MiniCalendarDayCellView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let date: Date
    var isSelected = false

    var isToday: Bool {
        return calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: IKPadding.micro) {
            Text(date, format: .dateTime.weekday(.narrow))
                .font(.caption)
                .foregroundColor(theme.color.textPrimary)

            ZStack {
                Text("00")
                    .opacity(0)
                Text(date, format: .dateTime.day())
            }
            .padding(value: .micro)
            .monospacedDigit()
            .font(.body.weight(.semibold))
            .foregroundColor(theme.color.textPrimary)
            .background(isToday ? Color.accentColor : Color.clear, in: .circle)
            .overlay {
                if isSelected, !isToday {
                    Circle().stroke(Color.accentColor, lineWidth: 1)
                }
            }
        }
    }
}

#Preview {
    HStack {
        MiniCalendarDayCellView(date: Date())
        MiniCalendarDayCellView(date: Date(timeIntervalSinceNow: -86400), isSelected: true)
    }
}
