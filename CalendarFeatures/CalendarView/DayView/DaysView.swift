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
import CalendarEventDetailsView
import InfiniteScrollViews
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

struct PagedDaysIndex: Equatable, Hashable {
    let date: Date
    let events: [CalendarCoreUI.UIEvent]

    static func == (lhs: Self, rhs: Self) -> Bool {
        return Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date) && lhs.events == rhs.events
    }

    static let empty = PagedDaysIndex(date: Date.distantPast, events: [])
}

private struct PagedInfiniteDateView<Content: View>: View {
    @Environment(\.calendar) private var calendar

    @State private var index = PagedDaysIndex.empty

    @Binding var selectedDate: Date

    let events: [Date: [CalendarCoreUI.UIEvent]]
    @ViewBuilder let content: (PagedDaysIndex) -> Content

    var body: some View {
        PagedInfiniteScrollView(
            changeIndex: $index,
            content: content,
            increaseIndexAction: increaseIndexAction,
            decreaseIndexAction: decreaseIndexAction,
            shouldAnimateBetween: shouldAnimateBetween,
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            backgroundColor: .clear
        )
        .onChange(of: events, initial: true) { _, newValue in
            index = PagedDaysIndex(date: selectedDate, events: eventsOfDay(selectedDate, store: newValue))
        }
        .onChange(of: index) { _, newValue in
            guard !calendar.isDate(newValue.date, inSameDayAs: selectedDate) else { return }
            selectedDate = newValue.date
        }
        .onChange(of: selectedDate) { _, newValue in
            guard !calendar.isDate(newValue, inSameDayAs: index.date) else { return }
            index = PagedDaysIndex(date: newValue, events: eventsOfDay(newValue))
        }
    }

    private func increaseIndexAction(_ index: PagedDaysIndex) -> PagedDaysIndex? {
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: index.date) else {
            return nil
        }

        return PagedDaysIndex(date: nextDate, events: eventsOfDay(nextDate))
    }

    private func decreaseIndexAction(_ index: PagedDaysIndex) -> PagedDaysIndex? {
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: index.date) else {
            return nil
        }

        return PagedDaysIndex(date: previousDate, events: eventsOfDay(previousDate))
    }

    private func shouldAnimateBetween(
        _ newValue: PagedDaysIndex, _ oldValue: PagedDaysIndex
    ) -> (Bool, UIPageViewController.NavigationDirection) {
        guard oldValue != .empty else { return (false, .forward) }

        let newDate = newValue.date
        let oldDate = oldValue.date
        return (newDate != oldDate, newDate > oldDate ? .forward : .reverse)
    }

    private func eventsOfDay(_ date: Date, store: [Date: [CalendarCoreUI.UIEvent]]? = nil) -> [CalendarCoreUI.UIEvent] {
        let day = date.startOfDay(calendar)

        let eventsStore = store ?? events
        return eventsStore[day, default: []]
    }
}

struct DaysView: View {
    @Environment(\.calendar) private var calendar

    @Environment(MainViewState.self) private var mainViewState
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var events: [Date: [CalendarCoreUI.UIEvent]] = [:]
    @State private var selectedEvent: CalendarCoreUI.UIEvent?

    var body: some View {
        @Bindable var mainViewState = mainViewState

        PagedInfiniteDateView(selectedDate: $mainViewState.selectedDate, events: events) { index in
            DayView(selectedEvent: $selectedEvent, date: index.date, events: index.events)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .sheet(item: $selectedEvent) { event in
            EventDetailsView(event: event)
        }
        .task {
            await observeCalendars()
        }
    }

    private func observeCalendars() async {
        let today = Date.now.startOfDay(calendar)
        let startDate = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        let endDate = calendar.date(byAdding: .day, value: 2, to: today) ?? today

        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(start: startDate.instant, end: endDate.instant) {
            let uiEvents = daySlices.values.flatMap { eventDaySlices in
                eventDaySlices.compactMap {
                    let account = calendarAccounts[Int($0.event.accountIdValue)]
                    return CalendarCoreUI.UIEvent(eventDaySlice: $0, userEmail: account?.user.email ?? "")
                }
            }

            let groupedEvents = Dictionary(grouping: uiEvents) { $0.startDate.startOfDay(calendar) }
            events = groupedEvents
        }
    }
}

#Preview {
    DaysView()
}
