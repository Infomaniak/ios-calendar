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

import CalendarCoreUI
import DesignSystem
import ESDSFoundation
import SwiftUI

struct MonthDayCellView: View {
    @Environment(\.esdsTheme) private var theme

    @Environment(MainViewState.self) private var mainViewState

    @SceneStorage("SelectedMode") private var selectedMode: CalendarViewMode = .day

    let day: Date
    let isInMonth: Bool
    let isToday: Bool
    let dayNumberHeight: CGFloat

    private var dayNumberColor: Color {
        if isToday {
            return theme.color.contentInverse
        }
        return isInMonth ? theme.color.contentPrimary : theme.color.contentTertiary
    }

    var body: some View {
        Button(action: selectDay) {
            Text(day, format: .dateTime.day())
                .font(.caption.weight(.semibold))
                .foregroundStyle(dayNumberColor)
                .padding(value: .micro)
                .background {
                    if isToday {
                        Circle()
                            .fill(theme.color.backgroundBrand)
                    }
                }
                .padding(value: .micro)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(isToday ? theme.color.backgroundBrand.opacity(0.1) : .clear)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide).day().month(.wide)))
    }

    private func selectDay() {
        selectedMode = .day
        mainViewState.selectedDate = day
    }
}
