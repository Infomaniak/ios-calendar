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
import InfiniteScrollViews
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

private struct PagedInfiniteWeekView<Content: View>: View {
    @Environment(\.calendar) private var calendar

    @Binding var selectedDate: Date

    @ViewBuilder let content: (Date) -> Content

    private var weekStart: Binding<Date> {
        Binding {
            calendar.weekStart(for: selectedDate)
        } set: { newWeekStart in
            selectedDate = newWeekStart
        }
    }

    var body: some View {
        PagedInfiniteScrollView(
            changeIndex: weekStart,
            content: content,
            increaseIndexAction: increaseIndexAction,
            decreaseIndexAction: decreaseIndexAction,
            shouldAnimateBetween: shouldAnimateBetween,
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            backgroundColor: .clear
        )
    }

    private func increaseIndexAction(_ index: Date) -> Date? {
        return calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.weekStart(for: index))
    }

    private func decreaseIndexAction(_ index: Date) -> Date? {
        return calendar.date(byAdding: .weekOfYear, value: -1, to: calendar.weekStart(for: index))
    }

    private func shouldAnimateBetween(_ newValue: Date, _ oldValue: Date) -> (Bool, UIPageViewController.NavigationDirection) {
        let isSameWeek = calendar.isDate(newValue, equalTo: oldValue, toGranularity: .weekOfYear)
        return (!isSameWeek, newValue > oldValue ? .forward : .reverse)
    }
}

struct WeeksView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.calendarAccounts) private var calendarAccounts

    @Environment(MainViewState.self) private var mainViewState

    @State private var viewModel = WeeksViewModel()

    var body: some View {
        @Bindable var mainViewState = mainViewState

        PagedInfiniteWeekView(selectedDate: $mainViewState.selectedDate) { date in
            WeekView(date: date)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .environment(viewModel)
        .task(id: calendar.weekStart(for: mainViewState.selectedDate)) {
            await observeCalendars(around: mainViewState.selectedDate)
        }
    }

    private func observeCalendars(around date: Date) async {
        let weekStart = calendar.weekStart(for: date)
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart),
              let endDate = calendar.date(byAdding: .weekOfYear, value: 2, to: weekStart) else {
            return
        }

        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(start: startDate.instant, end: endDate.instant) {
            guard !Task.isCancelled else { return }

            let uiEvents = daySlices.values.flatMap { eventDaySlices in
                eventDaySlices.compactMap {
                    let account = calendarAccounts[Int($0.event.accountIdValue)]
                    return CalendarCoreUI.UIEvent(eventDaySlice: $0, userEmail: account?.user.email ?? "")
                }
            }

            let newEventPages = Dictionary(grouping: uiEvents) { calendar.weekStart(for: $0.startDate) }
                .mapValues { weekEvents in
                    WeekPage(events: Dictionary(grouping: weekEvents) { $0.startDate.startOfDay(calendar) })
                }
            viewModel.eventPages = newEventPages
        }
    }
}

#Preview {
    WeeksView()
        .environment(MainViewState())
        .environment(\.calendarAccounts, [:])
}
