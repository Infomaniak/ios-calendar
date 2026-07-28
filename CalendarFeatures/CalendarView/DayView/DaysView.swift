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
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

struct DaysView: View {
    @Environment(MainViewState.self) private var mainViewState
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var events: [Date: [CalendarCoreUI.UIEvent]] = [:]
    @State private var selectedEvent: CalendarCoreUI.UIEvent?

    private var dates: [Date] {
        return [mainViewState.selectedDate]
    }

    var body: some View {
        ScrollView(.horizontal) {
            ForEach(dates, id: \.self) { date in
                DayView(onSelectEvent: { selectedEvent = $0 }, date: date, events: events[date] ?? [])
                    .containerRelativeFrame(.horizontal)
            }
        }
        .scrollTargetBehavior(.paging)
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
