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

    @State private var events = [Date: [CalendarCoreUI.UIEvent]]()

    let layout: MultipleDaysLayout

    var body: some View {
        @Bindable var mainViewState = mainViewState

        MultipleDaysContentView(layout: layout, events: events, selectedDate: $mainViewState.selectedDate)
            .task(id: layout.preloadedInterval(for: mainViewState.selectedDate, calendar: calendar)) {
                guard let interval = layout.preloadedInterval(for: mainViewState.selectedDate, calendar: calendar) else {
                    return
                }
                await observeEvents(in: interval, calendar: calendar)
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
            let accounts = await calendarAccounts

            let uiEvents = daySlices.values.flatMap { eventDaySlices in
                eventDaySlices.compactMap {
                    let account = accounts[Int($0.event.accountIdValue)]
                    return CalendarCoreUI.UIEvent(eventDaySlice: $0, userEmail: account?.user.email ?? "")
                }
            }

            guard !Task.isCancelled else { return }
            let groupedEvents = Dictionary(grouping: uiEvents) { $0.startDate.startOfDay(calendar) }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                events = groupedEvents
            }
        }
    }
}

#Preview("Week") {
    MultipleDaysView(layout: .week)
        .environment(MainViewState())
        .environment(\.calendarAccounts, [:])
}

#Preview("Three days") {
    MultipleDaysView(layout: .threeDays)
        .environment(MainViewState())
        .environment(\.calendarAccounts, [:])
}
