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

struct ReferenceDatePage: Hashable, Equatable {
    let referenceDate: Date
    let referenceDateInterval: Foundation.Calendar.Component
    let datesWithEventDots: [Date: [Color]]

    init(referenceDate: Date, referenceDateInterval: Foundation.Calendar.Component, datesWithEventDots: [Date: [Color]] = [:]) {
        self.referenceDate = referenceDate
        self.referenceDateInterval = referenceDateInterval
        self.datesWithEventDots = datesWithEventDots
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

    var body: some View {
        VStack(spacing: IKPadding.micro) {
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
                increaseIndexAction: { referenceDateAfter($0) },
                decreaseIndexAction: { referenceDateBefore($0) },
                shouldAnimateBetween: { targetPage, currentPage in
                    guard targetPage.referenceDateInterval == currentPage.referenceDateInterval else {
                        return (false, .forward)
                    }

                    let targetDate = targetPage.referenceDate
                    let currentDate = currentPage.referenceDate
                    return (targetDate != currentDate, targetDate > currentDate ? .forward : .reverse)
                },
                transitionStyle: .scroll,
                navigationOrientation: .horizontal,
                backgroundColor: .clear
            )
        }
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
    func updateCalendarDotsFor(date: Date, calendar: Foundation.Calendar) async {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year,
              let month = components.month else { return }

        let referenceStartOfDayDate = calendar.startOfDay(for: date)

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
                    let startOfDayDate = calendar.startOfDay(for: date)
                    return (startOfDayDate, colors)
                }
            )

            await MainActor.run {
                displayedPage = ReferenceDatePage(
                    referenceDate: referenceStartOfDayDate,
                    referenceDateInterval: displayMode.referenceDateInterval,
                    datesWithEventDots: datesWithEventDots
                )
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
