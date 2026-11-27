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
import DesignSystem
import ESDSFoundation
import SwiftUI

struct WeekdaysPicker: View {
    private struct WeekdayItem {
        let weekday: Locale.Weekday
        let symbol: String
        let name: String
    }

    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    @Binding var weekdays: Set<Locale.Weekday>

    private var orderedWeekdays: [WeekdayItem] {
        (0 ..< 7).map { offset in
            let index = (calendar.firstWeekday - 1 + offset) % 7
            return WeekdayItem(
                weekday: Locale.Weekday.calendarOrdered[index],
                symbol: calendar.veryShortStandaloneWeekdaySymbols[index],
                name: calendar.standaloneWeekdaySymbols[index]
            )
        }
    }

    var body: some View {
        HStack(spacing: IKPadding.mini) {
            ForEach(orderedWeekdays, id: \.weekday) { item in
                let isSelected = weekdays.contains(item.weekday)

                Button {
                    toggle(item.weekday)
                } label: {
                    Text(item.symbol)
                        .font(.body.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? theme.color.contentInverse : theme.color.contentPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(IKPadding.small)
                        .background {
                            Circle()
                                .fill(isSelected ? AnyShapeStyle(theme.color.backgroundBrand) : AnyShapeStyle(.fill.tertiary))
                        }
                        .minimumScaleFactor(0.5)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, value: .mini)
        .listRowInsets(EdgeInsets(top: 0, leading: IKPadding.mini, bottom: 0, trailing: IKPadding.mini))
    }

    private func toggle(_ weekday: Locale.Weekday) {
        if weekdays.contains(weekday) {
            guard weekdays.count > 1 else { return }
            weekdays.remove(weekday)
        } else {
            weekdays.insert(weekday)
        }
    }
}

#Preview {
    @Previewable @State var weekdays: Set<Locale.Weekday> = [.monday, .thursday]

    Form {
        WeekdaysPicker(weekdays: $weekdays)
    }
}
