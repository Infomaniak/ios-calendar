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

struct WeekHeaderView: View {
    @Environment(\.calendar) private var calendar
    @Environment(MiniCalendarViewModel.self) private var viewModel

    let page: ReferenceDatePage
    @Binding var selectedDate: Date

    var body: some View {
        Grid(alignment: .center, horizontalSpacing: IKPadding.micro, verticalSpacing: 0) {
            GridRow {
                ForEach(0 ..< 7, id: \.self) { column in
                    ZStack {
                        if let dayDate = calendar.date(byAdding: .day, value: column, to: page.referenceDate) {
                            Button {
                                selectedDate = calendar.startOfDay(for: dayDate)
                            } label: {
                                DayCellView(
                                    date: dayDate,
                                    isSelected: calendar.isDate(dayDate, inSameDayAs: selectedDate),
                                    eventDots: viewModel.eventDots(for: dayDate, calendar: calendar)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, value: .small)
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    WeekHeaderView(
        page: ReferenceDatePage(
            referenceDate: Calendar.current.weekStart(for: Date()),
            referenceDateInterval: MiniCalendarView.DisplayMode.week.referenceDateInterval
        ),
        selectedDate: $selectedDate
    )
    .environment(MiniCalendarViewModel())
}
