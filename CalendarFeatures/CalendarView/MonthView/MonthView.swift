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
import SwiftUI

private struct MonthObservationId: Hashable {
    // periphery:ignore - Read by the synthesized Hashable conformance.
    let monthStart: Date
    // periphery:ignore - Read by the synthesized Hashable conformance.
    let calendar: Calendar
}

struct MonthView: View {
    @Environment(\.calendar) private var calendar
    @Environment(MainViewState.self) private var mainViewState

    @AppStorage(UserDefaults.shared.key(.showWeekNumbers), store: .shared)
    private var showWeekNumbers = DefaultPreferences.showWeekNumbers

    @ScaledMetric(relativeTo: .caption2) private var weekNumberWidth: CGFloat = 24
    @ScaledMetric(relativeTo: .subheadline) private var dayNumberHeight: CGFloat = 24
    @ScaledMetric(relativeTo: .caption) private var eventTitleLineHeight: CGFloat = 16

    @State private var weekLayouts = [MonthGrid: [MonthWeekLayout]]()
    @State private var contentWidth = CGFloat.zero
    @State private var pagerHeight = CGFloat.zero

    private var displayedWeekNumberWidth: CGFloat? {
        showWeekNumbers ? weekNumberWidth : nil
    }

    private var metrics: MonthGridMetrics {
        MonthGridMetrics(
            containerSize: CGSize(width: contentWidth, height: pagerHeight),
            weekNumberWidth: displayedWeekNumberWidth ?? 0,
            dayNumberHeight: dayNumberHeight,
            laneHeight: eventTitleLineHeight + IKPadding.micro
        )
    }

    private var monthStart: Date {
        calendar.dateInterval(of: .month, for: mainViewState.selectedDate)?.start ?? mainViewState.selectedDate
    }

    private var selectedMonth: Binding<Date> {
        Binding {
            mainViewState.selectedDate
        } set: { newDate in
            guard !calendar.isDate(newDate, equalTo: mainViewState.selectedDate, toGranularity: .month) else { return }
            mainViewState.selectedDate = newDate
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MonthWeekdayHeaderView(weekNumberWidth: displayedWeekNumberWidth)

            TimelineView(.everyDay(calendar)) { timeline in
                CalendarPeriodPager(
                    component: .month,
                    periodOffsets: -1200 ..< 1201,
                    date: selectedMonth
                ) { pageMonthStart in
                    if let grid = MonthGrid(month: pageMonthStart, calendar: calendar) {
                        MonthPageView(
                            grid: grid,
                            weekLayouts: weekLayouts[grid],
                            metrics: metrics,
                            today: timeline.date,
                            showWeekNumbers: showWeekNumbers
                        )
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height + proxy.safeAreaInsets.bottom
            } action: { newHeight in
                pagerHeight = newHeight
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            contentWidth = newWidth
        }
        .task(id: MonthObservationId(monthStart: monthStart, calendar: calendar)) {
            await observeEvents(around: monthStart, calendar: calendar)
        }
    }

    private func observeEvents(around monthStart: Date, calendar: Foundation.Calendar) async {
        let grids = (-1 ... 1).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: monthStart).flatMap { MonthGrid(month: $0, calendar: calendar) }
        }

        await MonthEventsObserver.observe(grids: grids, calendar: calendar) { layouts in
            let cachedMonthsInterval = DateInterval(
                start: calendar.date(byAdding: .month, value: -2, to: monthStart) ?? monthStart,
                end: calendar.date(byAdding: .month, value: 3, to: monthStart) ?? monthStart
            )
            weekLayouts = weekLayouts
                .filter { cachedMonthsInterval.contains($0.key.monthInterval.start) }
                .merging(layouts) { _, newLayouts in newLayouts }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    MonthView()
        .environment(MainViewState())
}
