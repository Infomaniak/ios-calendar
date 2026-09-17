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

import SwiftUI

struct MiniCalendarPager: View {
    @Environment(\.calendar) private var calendar

    @State private var periods: CalendarPeriodCollection?
    @State private var visiblePeriod: Int?
    @State private var scrollPhase = ScrollPhase.idle

    let displayMode: MiniCalendarView.DisplayMode

    @Binding var selectedDate: Date
    @Binding var displayedPage: ReferenceDatePage

    private var periodOffsets: Range<Int> {
        switch displayMode {
        case .month:
            return -1200 ..< 1201
        case .week:
            return -5200 ..< 5201
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let periods {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(periods) { period in
                            MiniCalendarPage(
                                period: period,
                                displayMode: displayMode,
                                selectedDate: $selectedDate
                            )
                            .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $visiblePeriod, anchor: .center)
                .fixedSize(horizontal: false, vertical: true)
                .onScrollPhaseChange { previousPhase, phase in
                    scrollPhase = phase
                    guard previousPhase.isScrolling, phase == .idle else { return }
                    updateDisplayedPage()
                }
                .id(periods.origin)
                .id(displayMode)
                .id(calendar)
            }
        }
        .onChange(of: calendar, initial: true) { _, _ in
            resetPeriods()
        }
        .onChange(of: displayMode) { _, _ in
            resetPeriods()
        }
        .onChange(of: visiblePeriod) { _, _ in
            guard scrollPhase == .interacting || scrollPhase == .decelerating else { return }
            updateDisplayedPage()
        }
        .onChange(of: displayedPage) { _, page in
            if let index = periods?.index(for: page.referenceDate) {
                guard visiblePeriod != index else { return }
                withAnimation {
                    visiblePeriod = index
                }
            } else {
                resetPeriods()
            }
        }
    }

    private func resetPeriods() {
        let periods = CalendarPeriodCollection(
            calendar: calendar,
            component: displayMode.referenceDateInterval,
            origin: displayedPage.referenceDate,
            indices: periodOffsets
        )
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            self.periods = periods
            scrollPhase = .idle
            visiblePeriod = 0
            displayedPage = ReferenceDatePage(
                referenceDate: periods.origin,
                referenceDateInterval: displayMode.referenceDateInterval
            )
        }
    }

    private func updateDisplayedPage() {
        guard let index = visiblePeriod,
              let periods,
              periods.indices.contains(index) else { return }

        let page = ReferenceDatePage(
            referenceDate: periods[index].date,
            referenceDateInterval: displayMode.referenceDateInterval
        )
        guard displayedPage != page else { return }
        displayedPage = page
    }
}

private struct MiniCalendarPage: View {
    let period: CalendarPeriodCollection.Period
    let displayMode: MiniCalendarView.DisplayMode
    @Binding var selectedDate: Date

    var body: some View {
        let page = ReferenceDatePage(referenceDate: period.date, referenceDateInterval: displayMode.referenceDateInterval)

        switch displayMode {
        case .month:
            MonthHeaderView(page: page, selectedDate: $selectedDate)
        case .week:
            WeekHeaderView(page: page, selectedDate: $selectedDate)
        }
    }
}
