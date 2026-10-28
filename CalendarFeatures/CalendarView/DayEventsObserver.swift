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
import Foundation
import InfomaniakDI
import MultiplatformCalendar

struct DayGroupedEvents {
    var events = [Date: [UIEventSummary]]()
    var allDayEvents = [Date: [UIEventSummary]]()
}

enum DayEventsObserver {
    @concurrent
    static func observe(
        in interval: DateInterval,
        calendar: Foundation.Calendar,
        onUpdate: @escaping @MainActor @Sendable (DayGroupedEvents) -> Void
    ) async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(
            start: interval.start.instant,
            end: interval.end.instant
        )._throttle(for: .milliseconds(500)) {
            guard !Task.isCancelled else { return }
            var groupedEvents = DayGroupedEvents()
            for eventDaySlices in daySlices.values {
                for eventDaySlice in eventDaySlices {
                    let event = UIEventSummary(eventDaySlice: eventDaySlice)
                    let day = event.startDate.startOfDay(calendar)
                    if event.isAllDay {
                        groupedEvents.allDayEvents[day, default: []].append(event)
                    } else {
                        groupedEvents.events[day, default: []].append(event)
                    }
                }
            }

            guard !Task.isCancelled else { return }
            await onUpdate(groupedEvents)
        }
    }
}
