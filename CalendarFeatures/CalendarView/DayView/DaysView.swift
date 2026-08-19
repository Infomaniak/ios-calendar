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

private struct PagedInfiniteDateView<Content: View>: View {
    @Environment(\.calendar) private var calendar

    @Binding var selectedDate: Date

    @ViewBuilder let content: (Date) -> Content

    var body: some View {
        PagedInfiniteScrollView(
            changeIndex: $selectedDate,
            content: content,
            increaseIndexAction: increaseIndexAction,
            decreaseIndexAction: decreaseIndexAction,
            shouldAnimateBetween: shouldAnimateBetween,
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            backgroundColor: .clear
        )
    }

    private func increaseIndexAction(_ date: Date) -> Date? {
        return calendar.date(byAdding: .day, value: 1, to: date)
    }

    private func decreaseIndexAction(_ date: Date) -> Date? {
        return calendar.date(byAdding: .day, value: -1, to: date)
    }

    private func shouldAnimateBetween(_ newValue: Date, _ oldValue: Date) -> (Bool, UIPageViewController.NavigationDirection) {
        return (newValue != oldValue, newValue > oldValue ? .forward : .reverse)
    }
}

struct DaysView: View {
    @Environment(MainViewState.self) private var mainViewState
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var events: [Date: [CalendarCoreUI.UIEvent]] = [:]
    @State private var selectedEvent: CalendarCoreUI.UIEvent?

    var body: some View {
        @Bindable var mainViewState = mainViewState

        PagedInfiniteDateView(selectedDate: $mainViewState.selectedDate) { date in
            DayView(selectedEvent: $selectedEvent, date: date, events: events[date, default: []])
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
        let today = Calendar.current.startOfDay(for: .now)
        let startDate = Calendar.current.date(byAdding: .day, value: -2, to: today) ?? today
        let endDate = Calendar.current.date(byAdding: .day, value: 2, to: today) ?? today

        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(start: startDate.instant, end: endDate.instant) {
            let uiEvents = daySlices.values.flatMap { eventDaySlices in
                eventDaySlices.compactMap {
                    let account = calendarAccounts[Int($0.event.accountIdValue)]
                    return CalendarCoreUI.UIEvent(eventDaySlice: $0, userEmail: account?.user.email ?? "")
                }
            }

            let groupedEvents = Dictionary(grouping: uiEvents) { Calendar.current.startOfDay(for: $0.startDate) }
            events = groupedEvents
        }
    }
}

#Preview {
    DaysView()
}
