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

@Observable
final class DaysViewModel {
    var events = [Date: [UIEventSummary]]()
    var allDayEvents = [Date: [UIEventSummary]]()

    func events(for date: Date, calendar: Foundation.Calendar) -> [UIEventSummary] {
        return events[date.startOfDay(calendar)] ?? []
    }

    func allDayEvents(for date: Date, calendar: Foundation.Calendar) -> [UIEventSummary] {
        return allDayEvents[date.startOfDay(calendar)] ?? []
    }
}

struct DayPager: View {
    @Binding var selectedDate: Date

    var body: some View {
        CalendarPeriodPager(
            component: .day,
            periodOffsets: -36525 ..< 36526,
            date: $selectedDate
        ) { date in
            DayView(date: date)
        }
    }
}

struct DaysView: View {
    @Environment(\.calendar) private var calendar
    @Environment(MainViewState.self) private var mainViewState
    @State private var viewModel = DaysViewModel()

    var body: some View {
        @Bindable var mainViewState = mainViewState

        DayPager(selectedDate: $mainViewState.selectedDate)
            .environment(viewModel)
            .sensoryFeedback(trigger: mainViewState.selectedDate) { oldValue, newValue in
                guard !calendar.isDate(oldValue, inSameDayAs: newValue) else {
                    return nil
                }
                return .selection
            }
            .task(id: mainViewState.selectedDate) {
                await observeEventsAt(date: mainViewState.selectedDate, in: calendar)
            }
    }

    @concurrent
    private func observeEventsAt(date: Date, in calendar: Foundation.Calendar) async {
        let centerDate = date.startOfDay(calendar)
        let startDate = calendar.date(byAdding: .day, value: -3, to: centerDate) ?? centerDate
        let endDate = calendar.date(byAdding: .day, value: 3, to: centerDate) ?? centerDate

        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(
            start: startDate.instant,
            end: endDate.instant
        )._throttle(for: .milliseconds(500)) {
            guard !Task.isCancelled else { return }
            let uiEvents = daySlices.values.flatMap { eventDaySlices in
                eventDaySlices.map {
                    UIEventSummary(eventDaySlice: $0)
                }
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
                viewModel.events = groupedEvents
                viewModel.allDayEvents = groupedAllDayEvents
            }
        }
    }
}

#Preview {
    DaysView()
}
