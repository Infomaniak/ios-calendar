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
import Observation
import SwiftUI

@Observable
final class DaysViewModel {
    var events = [Date: [CalendarCoreUI.UIEvent]]()

    func events(for date: Date, calendar: Foundation.Calendar) -> [CalendarCoreUI.UIEvent] {
        return events[date.startOfDay(calendar)] ?? []
    }
}

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

    private func increaseIndexAction(_ index: Date) -> Date? {
        return calendar.date(byAdding: .day, value: 1, to: index)
    }

    private func decreaseIndexAction(_ index: Date) -> Date? {
        return calendar.date(byAdding: .day, value: -1, to: index)
    }

    private func shouldAnimateBetween(_ newValue: Date, _ oldValue: Date) -> (Bool, UIPageViewController.NavigationDirection) {
        return (newValue != oldValue, newValue > oldValue ? .forward : .reverse)
    }
}

struct DaysView: View {
    @Environment(\.calendar) private var calendar

    @Environment(MainViewState.self) private var mainViewState
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var viewModel = DaysViewModel()
    @State private var selectedEvent: CalendarCoreUI.UIEvent?

    @State private var observationTask: Task<Void, Never>?

    var body: some View {
        @Bindable var mainViewState = mainViewState

        PagedInfiniteDateView(selectedDate: $mainViewState.selectedDate) { date in
            DayView(selectedEvent: $selectedEvent, date: date)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .environment(viewModel)
        .sheet(item: $selectedEvent) { event in
            EventDetailsView(event: event)
        }
        .onChange(of: mainViewState.selectedDate, initial: true) { _, newValue in
            Task {
                observationTask?.cancel()

                observationTask = Task {
                    await observeCalendars(newValue)
                }
                await observationTask?.value
            }
        }
    }

    private func observeCalendars(_ date: Date) async {
        let centerDate = date.startOfDay(calendar)
        let startDate = calendar.date(byAdding: .day, value: -3, to: centerDate) ?? centerDate
        let endDate = calendar.date(byAdding: .day, value: 3, to: centerDate) ?? centerDate

        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(start: startDate.instant, end: endDate.instant) {
            guard !Task.isCancelled else {
                return
            }

            let uiEvents = daySlices.values.flatMap { eventDaySlices in
                eventDaySlices.compactMap {
                    let account = calendarAccounts[Int($0.event.accountIdValue)]
                    return CalendarCoreUI.UIEvent(eventDaySlice: $0, userEmail: account?.user.email ?? "")
                }
            }

            let groupedEvents = Dictionary(grouping: uiEvents) { $0.startDate.startOfDay(calendar) }
            viewModel.events = groupedEvents
        }
    }
}

#Preview {
    DaysView()
}
