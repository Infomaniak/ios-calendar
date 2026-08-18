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
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

struct MiniCalendarView: View {
    enum DisplayMode {
        case month
        case week
    }

    @Environment(\.calendar) private var calendar

    @State private var datesWithEventDots: [Date: [Color]] = [:]

    @Binding var displayMode: DisplayMode
    @Binding var selectedDate: Date
    @Binding var displayedDate: Date

    var body: some View {
        VStack(spacing: IKPadding.micro) {
            DayOfWeekView()
            if displayMode == .week {
                InfiniteScrollView(
                    referenceDateInterval: .weekOfYear,
                    selectedDate: $selectedDate,
                    displayedDate: $displayedDate
                ) { date in
                    WeekHeaderView(startDate: date, selectedDate: $selectedDate, datesWithEventDots: datesWithEventDots)
                }
            } else {
                InfiniteScrollView(
                    referenceDateInterval: .month,
                    selectedDate: $selectedDate,
                    displayedDate: $displayedDate
                ) { date in
                    MonthHeaderView(startDate: date, selectedDate: $selectedDate, datesWithEventDots: datesWithEventDots)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .task(id: displayedDate) {
            await updateCalendarDotsFor(date: displayedDate, calendar: calendar)
        }
    }

    @concurrent
    func updateCalendarDotsFor(date: Date, calendar: Foundation.Calendar) async {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year,
              let month = components.month else { return }

        @InjectService var calendarSDK: CalendarCoreGraph
        for await colorsByDay in calendarSDK.calendarManager.observeMonthlyCalendarColors(month: .init(
            year: Int32(year),
            month: Int32(month)
        )) {
            let datesWithEventDots: [Date: [Color]] = Dictionary(
                uniqueKeysWithValues: colorsByDay.compactMap { dayDate, colors in
                    guard let date = calendar.date(from: .init(
                        year: Int(dayDate.year),
                        month: Int(dayDate.month.ordinal + 1),
                        day: Int(dayDate.day)
                    )) else { return nil }

                    let colors = colors.map { Color(eventColor: $0.datavizContainerVariant) }
                    return (date, colors)
                }
            )

            await MainActor.run {
                self.datesWithEventDots = datesWithEventDots
            }
        }
    }
}

#Preview {
    @Previewable @State var displayMode: MiniCalendarView.DisplayMode = .week
    @Previewable @State var selectedDate = Date()
    @Previewable @State var displayedDate = Date()
    MiniCalendarView(displayMode: $displayMode, selectedDate: $selectedDate, displayedDate: $displayedDate)
}
