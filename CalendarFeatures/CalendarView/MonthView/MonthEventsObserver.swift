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

// FIXME: This logic should move KMP later
enum MonthEventsObserver {
    @concurrent
    static func observe(
        grids: [MonthGrid],
        calendar: Foundation.Calendar,
        onUpdate: @escaping @MainActor @Sendable ([MonthGrid: [MonthWeekLayout]]) -> Void
    ) async {
        guard let start = grids.map(\.interval.start).min(),
              let end = grids.map(\.interval.end).max() else { return }

        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(
            start: start.instant,
            end: end.instant
        )._throttle(for: .milliseconds(500)) {
            guard !Task.isCancelled else { return }

            var eventsByDay = [Date: [UIEventSummary]]()
            for eventDaySlices in daySlices.values {
                guard let firstSlice = eventDaySlices.first else { continue }
                let day = UIEventSummary(eventDaySlice: firstSlice).startDate.startOfDay(calendar)
                eventsByDay[day] = eventDaySlices.map { UIEventSummary(eventDaySlice: $0) }
            }

            var layouts = [MonthGrid: [MonthWeekLayout]]()
            for grid in grids {
                layouts[grid] = MonthWeekLayout.layouts(for: grid, eventsByDay: eventsByDay)
            }

            guard !Task.isCancelled else { return }
            await onUpdate(layouts)
        }
    }
}
