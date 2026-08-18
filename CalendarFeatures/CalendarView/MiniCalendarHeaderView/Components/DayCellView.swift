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

struct DayCellView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let date: Date
    var isSelected = false
    let eventDots: [Color]

    private var isToday: Bool {
        return calendar.isDateInToday(date)
    }

    private var displayedEventDots: [Color] {
        guard !(isSelected || isToday) else {
            return []
        }
        return eventDots
    }

    var body: some View {
        VStack(spacing: 2) {
            EventDotsView(eventDots: [])
                .hidden()

            ZStack {
                Text("00")
                    .hidden()
                Text(date, format: .dateTime.day())
            }

            EventDotsView(eventDots: displayedEventDots)
        }
        .padding(value: .micro)
        .monospacedDigit()
        .font(.body.weight(.semibold))
        .foregroundColor(theme.color.contentPrimary)
        .background(isToday ? Color.accentColor : Color.clear, in: .circle)
        .overlay {
            if isSelected, !isToday {
                Circle().stroke(Color.accentColor, lineWidth: 1)
                    .transition(.scale(scale: 0.5, anchor: .center).combined(with: .opacity))
            }
        }
        .padding(1)
        .geometryGroup()
    }
}

#Preview {
    HStack {
        DayCellView(date: Date(), eventDots: [])
        DayCellView(date: Date(timeIntervalSinceNow: -86400), isSelected: true, eventDots: [])
    }
}
