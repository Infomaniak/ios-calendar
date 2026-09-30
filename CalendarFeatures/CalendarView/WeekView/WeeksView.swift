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
import Observation
import SwiftUI

struct WeekPage: Equatable {
    let events: [Date: [CalendarCoreUI.UIEvent]]
}

@Observable
@MainActor
final class WeeksViewModel {
    var eventPages = [Date: WeekPage]()

    func events(forWeekOf date: Date, calendar: Foundation.Calendar) -> [Date: [CalendarCoreUI.UIEvent]] {
        return eventPages[calendar.weekStart(for: date)]?.events ?? [:]
    }
}

struct WeekPager: View {
    @Environment(\.calendar) private var calendar

    @Binding var selectedDate: Date

    private var weekStart: Binding<Date> {
        Binding {
            calendar.weekStart(for: selectedDate)
        } set: { newWeekStart in
            guard !calendar.isDate(newWeekStart, equalTo: selectedDate, toGranularity: .weekOfYear) else { return }
            selectedDate = newWeekStart
        }
    }

    var body: some View {
        GeometryReader { proxy in
            CalendarPeriodPager(
                component: .weekOfYear,
                periodOffsets: -5218 ..< 5219,
                date: weekStart
            ) { date in
                WeekView(date: date)
                    .safeAreaPadding(.bottom, proxy.safeAreaInsets.bottom)
            }
            .ignoresSafeArea(.all, edges: [.top, .bottom])
        }
    }
}

struct WeeksView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.calendarAccounts) private var calendarAccounts

    @Environment(MainViewState.self) private var mainViewState

    @State private var viewModel = WeeksViewModel()

    var body: some View {
        @Bindable var mainViewState = mainViewState

        WeekPager(selectedDate: $mainViewState.selectedDate)
            .environment(viewModel)
            .task(id: calendar.weekStart(for: mainViewState.selectedDate)) {
                await observeEventsAround(date: mainViewState.selectedDate, in: calendar)
            }
    }

    @concurrent
    private func observeEventsAround(date: Date, in calendar: Foundation.Calendar) async {
        let weekStart = calendar.weekStart(for: date)
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart),
              let endDate = calendar.date(byAdding: .weekOfYear, value: 2, to: weekStart) else {
            return
        }

        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(
            start: startDate.instant,
            end: endDate.instant
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
            let newEventPages = Dictionary(grouping: uiEvents) { calendar.weekStart(for: $0.startDate) }
                .mapValues { weekEvents in
                    WeekPage(events: Dictionary(grouping: weekEvents) { $0.startDate.startOfDay(calendar) })
                }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                viewModel.eventPages = newEventPages
            }
        }
    }
}

#Preview {
    WeeksView()
        .environment(MainViewState())
        .environment(\.calendarAccounts, [:])
}
