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
import InfiniteScrollViews
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

struct MiniCalendarView: View {
    enum DisplayMode {
        case month
        case week

        var referenceDateInterval: Foundation.Calendar.Component {
            switch self {
            case .month:
                return .month
            case .week:
                return .weekOfYear
            }
        }

        func referenceDate(for date: Date, calendar: Foundation.Calendar) -> Date {
            calendar.dateInterval(of: referenceDateInterval, for: date)?.start ?? calendar.startOfDay(for: date)
        }
    }

    @Environment(\.calendar) private var calendar

    @State private var datesWithEventDots: [Date: [Color]] = [:]

    @Binding var displayMode: DisplayMode
    @Binding var selectedDate: Date
    @Binding var displayedDate: Date

    var body: some View {
        VStack(spacing: IKPadding.micro) {
            DayOfWeekView()
            switch displayMode {
            case .week:
                MiniCalendarPagedInfiniteScrollView(
                    referenceDateInterval: displayMode.referenceDateInterval,
                    referenceDate: $displayedDate
                ) { referenceDate in
                    WeekHeaderView(startDate: referenceDate, selectedDate: $selectedDate, datesWithEventDots: datesWithEventDots)
                }
            case .month:
                MiniCalendarPagedInfiniteScrollView(
                    referenceDateInterval: displayMode.referenceDateInterval,
                    referenceDate: $displayedDate
                ) { referenceDate in
                    MonthHeaderView(startDate: referenceDate, selectedDate: $selectedDate, datesWithEventDots: datesWithEventDots)
                }
            }
        }
        .task(id: displayedDate) {
            await updateCalendarDotsFor(date: displayedDate, calendar: calendar)
        }
        .onChange(of: selectedDate) { _, newValue in
            withAnimation {
                displayedDate = displayMode.referenceDate(for: newValue, calendar: calendar)
            }
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

struct MiniCalendarPagedInfiniteScrollView<ContentView: View>: View {
    @Environment(\.calendar) private var calendar

    let referenceDateInterval: Foundation.Calendar.Component
    @Binding var referenceDate: Date
    @ViewBuilder let content: (Date) -> ContentView

    var body: some View {
        PagedInfiniteScrollView(
            changeIndex: $referenceDate,
            content: { referenceDate in
                content(referenceDate)
            },
            increaseIndexAction: { referenceDateAfter($0) },
            decreaseIndexAction: { referenceDateBefore($0) },
            shouldAnimateBetween: { targetDate, currentDate in
                (targetDate != currentDate, targetDate > currentDate ? .forward : .reverse)
            },
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            backgroundColor: .clear
        )
        .id(referenceDateInterval)
    }

    private func referenceDateAfter(_ date: Date) -> Date? {
        calendar.date(byAdding: referenceDateInterval, value: 1, to: date)
    }

    private func referenceDateBefore(_ date: Date) -> Date? {
        calendar.date(byAdding: referenceDateInterval, value: -1, to: date)
    }
}

#Preview {
    @Previewable @State var displayMode: MiniCalendarView.DisplayMode = .week
    @Previewable @State var selectedDate = Date()
    @Previewable @State var displayedDate = Date()
    MiniCalendarView(displayMode: $displayMode, selectedDate: $selectedDate, displayedDate: $displayedDate)
}
