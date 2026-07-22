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
import MultiplatformCalendar

enum PlanningItem: Hashable {
    case weekHeader(Date)
    case empty(Date)
    case event(CalendarCoreUI.UIEvent)
}

struct PlanningDay: Identifiable, Hashable {
    let date: Date
    let events: [CalendarCoreUI.UIEvent]
    let isWeekStart: Bool

    init(date: Date, events: [CalendarCoreUI.UIEvent]) {
        self.date = date
        self.events = events
        isWeekStart = Calendar.current.component(.weekday, from: date) == Calendar.current.firstWeekday
    }

    var id: Date {
        date
    }
}

extension PlanningDay {
    var items: [PlanningItem] {
        var items: [PlanningItem] = []
        if isWeekStart {
            items.append(.weekHeader(date))
        }

        let events = events.map(PlanningItem.event)
        if events.isEmpty {
            items.append(.empty(date))
        } else {
            items.append(contentsOf: events)
        }
        return items
    }

    static func makeWindow(
        startDate: Date,
        dayCount: Int,
        eventsByDay: [Date: [CalendarCoreUI.UIEvent]],
        calendar: Foundation.Calendar
    ) -> [PlanningDay] {
        var days: [PlanningDay] = []
        days.reserveCapacity(dayCount)
        for offset in 0 ..< dayCount {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let events = (eventsByDay[dayStart] ?? []).sorted { $0.startDate < $1.startDate }
            days.append(PlanningDay(date: dayStart, events: events))
        }
        return days
    }
}
