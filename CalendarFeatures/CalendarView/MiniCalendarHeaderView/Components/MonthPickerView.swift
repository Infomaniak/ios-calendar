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
import InfiniteScrollViews
import SwiftUI

struct MonthPickerView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    @State private var currentPage: Date

    @Binding var selectedDate: Date

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        _currentPage = State(initialValue: Calendar.current.monthStart(for: selectedDate.wrappedValue))
    }

    var body: some View {
        InfiniteScrollView(
            changeIndex: currentPage,
            increaseIndexAction: referenceDateAfter,
            decreaseIndexAction: referenceDateBefore,
            orientation: .horizontal
        ) { monthDate in
            HStack(spacing: IKPadding.micro) {
                if shouldDisplayYear(for: monthDate) {
                    Text(monthDate, format: .dateTime.year())
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, IKPadding.small)
                        .padding(.vertical, IKPadding.micro)
                }

                Button {
                    selectedDate = monthDate
                } label: {
                    Text(monthDate, format: .dateTime.month(.abbreviated))
                        .foregroundStyle(isSelected(monthDate) ? theme.color.contentInverse : theme.color.contentPrimary)
                        .padding(.horizontal, IKPadding.small)
                        .padding(.vertical, IKPadding.micro)
                        .background(isSelected(monthDate) ? AnyShapeStyle(.tint) : AnyShapeStyle(theme.color.backgroundDisabled),
                                    in: .capsule)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, IKPadding.micro)
        }
        .padding(.bottom, value: .mini)
    }

    private func referenceDateAfter(_ page: Date) -> Date? {
        return calendar.date(byAdding: .month, value: 1, to: page)
    }

    private func referenceDateBefore(_ page: Date) -> Date? {
        return calendar.date(byAdding: .month, value: -1, to: page)
    }

    private func shouldDisplayYear(for date: Date) -> Bool {
        return calendar.component(.month, from: date) == 1
    }

    private func isSelected(_ date: Date) -> Bool {
        return calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    MonthPickerView(selectedDate: $selectedDate)
}
