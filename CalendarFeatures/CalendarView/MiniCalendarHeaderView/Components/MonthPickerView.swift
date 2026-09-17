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
import SwiftUI

struct MonthPickerView: View {
    private enum Constants {
        static let monthOffsets = -1200 ..< 1201
    }

    @Environment(\.calendar) private var calendar

    @State private var months: CalendarPeriodCollection?
    @State private var scrollPosition = ScrollPosition(idType: Int.self)

    @Binding var selectedDate: Date
    @Binding var displayedPage: ReferenceDatePage

    var body: some View {
        VStack(spacing: IKPadding.small) {
            Divider()
                .padding(.horizontal, value: .small)

            if let months {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(months) { month in
                            MonthPickerCell(
                                month: month,
                                selectedDate: $selectedDate,
                                displayedPage: $displayedPage
                            )
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollPosition($scrollPosition, anchor: .center)
                .fixedSize(horizontal: false, vertical: true)
                .id(months.origin)
            }
        }
        .padding(.vertical, value: .mini)
        .onChange(of: calendar, initial: true) { _, _ in
            resetMonths(around: displayedPage.referenceDate)
        }
        .onChange(of: displayedPage.referenceDate) { _, newValue in
            if let index = months?.index(for: newValue) {
                withAnimation {
                    scrollPosition.scrollTo(id: index)
                }
            } else {
                resetMonths(around: newValue)
            }
        }
    }

    private func resetMonths(around month: Date) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            months = CalendarPeriodCollection(
                calendar: calendar,
                component: .month,
                origin: month,
                indices: Constants.monthOffsets
            )
            scrollPosition.scrollTo(id: 0)
        }
    }
}

private struct MonthPickerCell: View {
    @Environment(\.calendar) private var calendar

    let month: CalendarPeriodCollection.Period

    @Binding var selectedDate: Date
    @Binding var displayedPage: ReferenceDatePage

    var body: some View {
        let date = month.date

        HStack(spacing: IKPadding.micro) {
            if calendar.component(.month, from: date) == 1 {
                Text(date, format: .dateTime.year())
                    .font(.subheadline.weight(.emphasized))
                    .padding(.horizontal, IKPadding.small)
                    .padding(.vertical, IKPadding.micro)
            }

            MonthButton(date: date, selectedDate: $selectedDate, displayedPage: $displayedPage)
        }
        .padding(.horizontal, IKPadding.micro)
    }
}

private struct MonthButton: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let date: Date

    @Binding var selectedDate: Date
    @Binding var displayedPage: ReferenceDatePage

    private var isCurrentMonth: Bool {
        return calendar.isDate(date, equalTo: .now, toGranularity: .month)
    }

    private var isSelected: Bool {
        return calendar.isDate(date, equalTo: displayedPage.referenceDate, toGranularity: .month)
    }

    var body: some View {
        Button {
            selectedDate = date
        } label: {
            Text(date, format: .dateTime.month(.abbreviated))
                .foregroundStyle(isCurrentMonth ? theme.color.contentInverse : theme.color.contentPrimary)
                .padding(.horizontal, IKPadding.small)
                .padding(.vertical, IKPadding.micro)
                .background(
                    isCurrentMonth ? Color.accentColor : theme.color.backgroundDatavizGrayDim1.opacity(0.1),
                    in: Capsule()
                )
                .overlay {
                    if isSelected, !isCurrentMonth {
                        Capsule()
                            .strokeBorder(Color.accentColor)
                    }
                }
                .geometryGroup()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    @Previewable @State var displayedPage = ReferenceDatePage(
        referenceDate: Date(),
        referenceDateInterval: .month
    )
    MonthPickerView(selectedDate: $selectedDate, displayedPage: $displayedPage)
}
