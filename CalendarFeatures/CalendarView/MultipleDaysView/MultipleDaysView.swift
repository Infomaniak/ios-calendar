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

private struct AllDayBarVersion: Hashable {
    let events: [Date: [UIEventSummary]]
    let visibleRowCount: Int
}

struct MultipleDaysView: View {
    @Environment(\.calendar) private var calendar
    @Environment(MainViewState.self) private var mainViewState

    @State private var events = [Date: [UIEventSummary]]()
    @State private var allDayEvents = [Date: [UIEventSummary]]()

    let layout: MultipleDaysLayout
    let pagerScrollSync: CalendarPeriodPagerScrollSync

    private var visibleAllDayRowCount: Int {
        layout.maxEventCount(in: allDayEvents, selectedDate: mainViewState.selectedDate, calendar: calendar)
    }

    var body: some View {
        @Bindable var mainViewState = mainViewState

        MultipleDaysContentView(
            layout: layout,
            events: events,
            pagerScrollSync: pagerScrollSync,
            selectedDate: $mainViewState.selectedDate
        )
        .task(id: layout.preloadedInterval(for: mainViewState.selectedDate, calendar: calendar)) {
            guard let interval = layout.preloadedInterval(for: mainViewState.selectedDate, calendar: calendar) else {
                return
            }
            await observeEvents(in: interval, calendar: calendar)
        }
        .additionalSafeAreaBarView(
            id: layout,
            version: AllDayBarVersion(events: allDayEvents, visibleRowCount: visibleAllDayRowCount)
        ) {
            MultipleDaysAllDayEventsView(
                layout: layout,
                events: allDayEvents,
                visibleRowCount: visibleAllDayRowCount,
                pagerScrollSync: pagerScrollSync
            )
        }
    }

    private func observeEvents(in interval: DateInterval, calendar: Foundation.Calendar) async {
        await DayEventsObserver.observe(in: interval, calendar: calendar) { groupedEvents in
            events = groupedEvents.events
            allDayEvents = groupedEvents.allDayEvents
        }
    }
}

#Preview("Week") {
    @Previewable @State var pagerScrollSync = CalendarPeriodPagerScrollSync()
    MultipleDaysView(layout: .week, pagerScrollSync: pagerScrollSync)
        .environment(MainViewState())
}

#Preview("Three days") {
    @Previewable @State var pagerScrollSync = CalendarPeriodPagerScrollSync()
    MultipleDaysView(layout: .threeDays, pagerScrollSync: pagerScrollSync)
        .environment(MainViewState())
}
