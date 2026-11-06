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

    @State private var weekLayouts = [MonthGrid: [MonthWeekLayout]]()

    private var monthStart: Date {
        calendar.dateInterval(of: .month, for: mainViewState.selectedDate)?.start ?? mainViewState.selectedDate
    }

    var body: some View {
        @Bindable var mainViewState = mainViewState

        MonthContentView(weekLayouts: weekLayouts, selectedDate: $mainViewState.selectedDate)
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
