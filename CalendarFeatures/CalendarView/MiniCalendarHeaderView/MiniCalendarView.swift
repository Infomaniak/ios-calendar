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
import CalendarCoreUI
import DesignSystem
import InfiniteScrollViews
import InfomaniakDI
import MultiplatformCalendar
import Observation
import SwiftUI

struct ReferenceDatePage: Hashable, Equatable {
    let referenceDate: Date
    let referenceDateInterval: Foundation.Calendar.Component
}

@Observable
final class MiniCalendarViewModel {
    var datesWithEventDots = [Date: [Color]]()

    func eventDots(for date: Date, calendar: Foundation.Calendar) -> [Color] {
        return datesWithEventDots[calendar.startOfDay(for: date)] ?? []
    }
}

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

    @Binding var displayMode: DisplayMode
    @Binding var selectedDate: Date
    @Binding var displayedPage: ReferenceDatePage

    @State private var viewModel = MiniCalendarViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DayOfWeekView()
            PagedInfiniteScrollView(
                changeIndex: $displayedPage,
                content: { page in
                    switch displayMode {
                    case .month:
                        MonthHeaderView(page: page, selectedDate: $selectedDate)
                    case .week:
                        WeekHeaderView(page: page, selectedDate: $selectedDate)
                    }
                },
                increaseIndexAction: referenceDateAfter,
                decreaseIndexAction: referenceDateBefore,
                shouldAnimateBetween: shouldAnimateBetween,
                transitionStyle: .scroll,
                navigationOrientation: .horizontal,
                backgroundColor: .clear
            )
            .id(displayMode)

            if displayMode == .month {
                MonthPickerView(selectedDate: $selectedDate)
            }
        }
        .environment(viewModel)
        .task(id: displayedPage.referenceDate) {
            await updateCalendarDotsFor(date: displayedPage.referenceDate, calendar: calendar)
        }
        .onChange(of: selectedDate) { _, newValue in
            withAnimation {
                displayedPage = ReferenceDatePage(
                    referenceDate: displayMode.referenceDate(for: newValue, calendar: calendar),
                    referenceDateInterval: displayMode.referenceDateInterval
                )
            }
        }
    }

    private func shouldAnimateBetween(targetPage: ReferenceDatePage,
                                      currentPage: ReferenceDatePage) -> (Bool, UIPageViewController.NavigationDirection) {
        guard targetPage.referenceDateInterval == currentPage.referenceDateInterval else {
            return (false, .forward)
        }

        let targetDate = targetPage.referenceDate
        let currentDate = currentPage.referenceDate
        return (targetDate != currentDate, targetDate > currentDate ? .forward : .reverse)
    }

    private func referenceDateAfter(_ page: ReferenceDatePage) -> ReferenceDatePage? {
        guard let date = calendar.date(byAdding: displayMode.referenceDateInterval, value: 1, to: page.referenceDate) else {
            return nil
        }
        return ReferenceDatePage(referenceDate: date, referenceDateInterval: displayMode.referenceDateInterval)
    }

    private func referenceDateBefore(_ page: ReferenceDatePage) -> ReferenceDatePage? {
        guard let date = calendar.date(byAdding: displayMode.referenceDateInterval, value: -1, to: page.referenceDate) else {
            return nil
        }
        return ReferenceDatePage(referenceDate: date, referenceDateInterval: displayMode.referenceDateInterval)
    }

    @concurrent
    private func updateCalendarDotsFor(date: Date, calendar: Foundation.Calendar) async {
        guard let previousMonthDate = calendar.date(byAdding: .month, value: -2, to: date),
              let nextMonthDate = calendar.date(byAdding: .month, value: 2, to: date),
              let previousYearMonth = YearMonth.fromDate(date: previousMonthDate, calendar: calendar),
              let nextYearMonth = YearMonth.fromDate(date: nextMonthDate, calendar: calendar) else {
            return
        }

        @InjectService var calendarSDK: CalendarCoreGraph
        for await colorsByDay in calendarSDK.calendarManager.observeMonthlyCalendarColors(
            startMonth: previousYearMonth,
            endMonth: nextYearMonth
        ) {
            let datesWithEventDots: [Date: [Color]] = Dictionary(
                uniqueKeysWithValues: colorsByDay.compactMap { dayDate, visibleColors in
                    guard let date = calendar.date(from: .init(
                        year: Int(dayDate.year),
                        month: Int(dayDate.month.ordinal + 1),
                        day: Int(dayDate.day)
                    )) else { return nil }

                    let colors = visibleColors.map { Color(argb: $0.colors.sourceColor) }
                    let startOfDayDate = calendar.startOfDay(for: date)
                    return (startOfDayDate, colors)
                }
            )

            await MainActor.run {
                viewModel.datesWithEventDots = datesWithEventDots
            }
        }
    }
}

#Preview {
    @Previewable @State var displayMode: MiniCalendarView.DisplayMode = .week
    @Previewable @State var selectedDate = Date()
    @Previewable @State var displayedPage = ReferenceDatePage(
        referenceDate: Date(),
        referenceDateInterval: MiniCalendarView.DisplayMode.week.referenceDateInterval
    )
    MiniCalendarView(displayMode: $displayMode, selectedDate: $selectedDate, displayedPage: $displayedPage)
}
