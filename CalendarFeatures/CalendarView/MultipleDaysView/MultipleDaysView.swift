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

import AsyncAlgorithms
import CalendarCore
import CalendarCoreUI
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

struct MultipleDaysView: View {
    @Environment(\.calendar) private var calendar

    @Environment(\.calendarAccounts) private var calendarAccounts
    @Environment(MainViewState.self) private var mainViewState

    @State private var events = [Date: [UIEventSummary]]()
    @State private var allDayEvents = [Date: [UIEventSummary]]()

    let layout: MultipleDaysLayout
    let pagerScrollSync: CalendarPeriodPagerScrollSync

    var body: some View {
        @Bindable var mainViewState = mainViewState

        MultipleDaysContentView(
            layout: layout,
            events: events,
            pagerScrollSync: pagerScrollSync,
            selectedDate: $mainViewState.selectedDate
        )
        .id(layout)
        .task(id: layout.preloadedInterval(for: mainViewState.selectedDate, calendar: calendar)) {
            guard let interval = layout.preloadedInterval(for: mainViewState.selectedDate, calendar: calendar) else {
                return
            }
            await observeEvents(in: interval, calendar: calendar)
        }
        .additionalSafeAreaBarView(id: layout, version: allDayEvents) {
            MultipleDaysAllDayEventsView(layout: layout, events: allDayEvents, pagerScrollSync: pagerScrollSync)
        }
    }

    @concurrent
    private func observeEvents(in interval: DateInterval, calendar: Foundation.Calendar) async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(
            start: interval.start.instant,
            end: interval.end.instant
        )._throttle(for: .milliseconds(500)) {
            guard !Task.isCancelled else { return }
            let uiEvents = daySlices.values.flatMap { eventDaySlices in
                eventDaySlices.compactMap { UIEventSummary(eventDaySlice: $0) }
            }

            guard !Task.isCancelled else { return }
            var groupedEvents = [Date: [UIEventSummary]]()
            var groupedAllDayEvents = [Date: [UIEventSummary]]()
            for event in uiEvents {
                let day = event.startDate.startOfDay(calendar)
                if event.isAllDay {
                    groupedAllDayEvents[day, default: []].append(event)
                } else {
                    groupedEvents[day, default: []].append(event)
                }
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                events = groupedEvents
                allDayEvents = groupedAllDayEvents
            }
        }
    }
}

#Preview("Week") {
    @Previewable @State var pagerScrollSync = CalendarPeriodPagerScrollSync()
    MultipleDaysView(layout: .week, pagerScrollSync: pagerScrollSync)
        .environment(MainViewState())
        .environment(\.calendarAccounts, [:])
}

#Preview("Three days") {
    @Previewable @State var pagerScrollSync = CalendarPeriodPagerScrollSync()
    MultipleDaysView(layout: .threeDays, pagerScrollSync: pagerScrollSync)
        .environment(MainViewState())
        .environment(\.calendarAccounts, [:])
}
