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
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

struct NextEventTimelineView<Content: View>: View {
    @State private var nextEvent: CalendarCoreUI.UIEvent?

    @ViewBuilder var content: (CalendarCoreUI.UIEvent) -> Content

    var body: some View {
        TimelineView(.everyMinute) { context in
            ZStack {
                if let nextEvent {
                    content(nextEvent)
                }
            }
            .task {
                await observeNextEvent()
            }
        }
    }

    @concurrent
    private func observeNextEvent() async {
        let start = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 2, to: start) else { return }

        @InjectService var calendarSDK: CalendarCoreGraph
        for await events in calendarSDK.calendarManager.observeEvents(start: start.instant, end: end.instant) {
            let uiEvents = events.compactMap { CalendarCoreUI.UIEvent(event: $0, userEmail: "") }
            await updateNextEvent(from: uiEvents)
        }
    }

    @concurrent
    private func updateNextEvent(from uiEvents: [CalendarCoreUI.UIEvent]) async {
        let now = Date()
        let nextTimedEvents = uiEvents
            .filter { !$0.isAllDay && $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }

        if let nextTimedEvent = nextTimedEvents.first {
            await MainActor.run {
                self.nextEvent = nextTimedEvent
            }
            return
        }

        let nextAllDayEvent = uiEvents
            .filter(\.isAllDay)
            .sorted { $0.startDate < $1.startDate }
            .first

        await MainActor.run {
            self.nextEvent = nextAllDayEvent
        }
    }
}

#Preview {
    NextEventTimelineView { nextEvent in
        Text(nextEvent.title)
    }
}
