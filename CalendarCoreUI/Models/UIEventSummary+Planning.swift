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
import Foundation
import MultiplatformCalendar

public extension Sequence<UIEventSummary> {
    func sortedForPlanning() -> [UIEventSummary] {
        sorted { lhs, rhs in
            if lhs.isAllDay != rhs.isAllDay {
                return lhs.isAllDay
            }
            return lhs.startDate < rhs.startDate
        }
    }

    func filterUpcomingAttending(at date: Date) -> [UIEventSummary] {
        filter { event in
            guard event.endDate > date, event.status != .cancelled else { return false }

            let hasAccepted = event.myStatus == .accepted
            let requiresNoReply = event.myStatus == nil && !event.hasAttendees
            return hasAccepted || requiresNoReply
        }
    }
}

public extension CalendarManager {
    func planningEvents(on day: Date, calendar: Foundation.Calendar) async -> [UIEventSummary] {
        let startOfDay = day.startOfDay(calendar)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        for await daySlices in observeDaySlices(start: startOfDay.instant, end: endOfDay.instant) {
            return daySlices.values
                .flatMap { eventDaySlices in
                    eventDaySlices.map { UIEventSummary(eventDaySlice: $0) }
                }
                .filter { $0.startDate.startOfDay(calendar) == startOfDay }
                .sortedForPlanning()
        }
        return []
    }
}
