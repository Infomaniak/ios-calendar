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

import CalendarCoreUI
import Foundation
import InfomaniakDI
import KmpCalendar
import SwiftUI

struct PlanningDay: Identifiable, Hashable {
    let date: Date
    let events: [CalendarCoreUI.UIEvent]

    var id: Date {
        date
    }
}

public struct PlanningView: View {
    @State private var planningDays: [PlanningDay] = []

    public init() {}

    public var body: some View {
        List {
            ForEach(planningDays) { day in
                Section {
                    ForEach(day.events) { event in
                        HStack {
                            VStack(alignment: .leading) {
                                if let startDate = event.startDate {
                                    Text(startDate, style: .time)
                                }
                                if let endDate = event.endDate {
                                    Text(endDate, style: .time)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(event.title)
                        }
                    }
                } header: {
                    Text(day.date, style: .date)
                }
            }
        }
        .task {
            await observeEvents()
        }
    }

    private func observeEvents() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        let calendars = await getCalendars()
        guard let firstCalendar = calendars.first else { return }

        for await events in calendarSDK.calendarManager.observeEvents(calendarId: firstCalendar.idValue) {
            let uiEvents = events.map { UIEvent(event: $0) }

            let grouped = Dictionary(grouping: uiEvents) { event in
                Calendar.current.startOfDay(for: event.startDate ?? .distantPast)
            }

            let days = grouped
                .map { date, events -> PlanningDay in
                    let sortedEvents = events.sorted {
                        ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast)
                    }
                    return PlanningDay(date: date, events: sortedEvents)
                }
                .sorted { $0.date < $1.date }

            withAnimation {
                planningDays = days
            }
        }
    }

    private func getCalendars() async -> [KmpCalendar.Calendar] {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            return calendars
        }
        return []
    }
}

#Preview {
    PlanningView()
}
