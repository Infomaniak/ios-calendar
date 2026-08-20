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

struct MonthHeaderView: View {
    @Environment(\.calendar) private var calendar

    let page: ReferenceDatePage
    @Binding var selectedDate: Date

    private let maximumRowCount = 6

    private var monthStart: Date {
        calendar.monthStart(for: page.referenceDate)
    }

    private var gridStart: Date {
        calendar.weekStart(for: monthStart)
    }

    private var rowCount: Int {
        guard let monthEnd = calendar.dateInterval(of: .month, for: monthStart)?.end else {
            return 1
        }

        let dayCount = calendar.dateComponents([.day], from: gridStart, to: monthEnd).day ?? 0
        return min(max((dayCount + 6) / 7, 4), maximumRowCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< maximumRowCount, id: \.self) { row in
                HStack(spacing: IKPadding.micro) {
                    ForEach(0 ..< 7, id: \.self) { column in
                        let dayIndex = row * 7 + column

                        ZStack {
                            if row >= rowCount {
                                DayCellView(date: gridStart, eventDots: [])
                                    .hidden()
                                    .accessibilityHidden(true)
                            } else if let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: gridStart) {
                                Button {
                                    selectedDate = calendar.startOfDay(for: dayDate)
                                } label: {
                                    DayCellView(
                                        date: dayDate,
                                        isSelected: calendar.isDate(dayDate, inSameDayAs: selectedDate),
                                        eventDots: page.datesWithEventDots[dayDate] ?? []
                                    )
                                    .opacity(
                                        calendar.isDate(
                                            dayDate,
                                            equalTo: monthStart,
                                            toGranularity: .month
                                        ) ? 1 : 0.5
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .geometryGroup()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    MonthHeaderView(
        page: ReferenceDatePage(
            referenceDate: Calendar.current.monthStart(for: Date()),
            referenceDateInterval: MiniCalendarView.DisplayMode.month.referenceDateInterval
        ),
        selectedDate: $selectedDate
    )
}
