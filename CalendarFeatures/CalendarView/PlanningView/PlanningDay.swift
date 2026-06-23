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
import KmpCalendar

struct PlanningDay: Identifiable, Hashable {
    let date: Date
    let events: [CalendarCoreUI.UIEvent]

    var id: Date {
        date
    }
}

extension PlanningDay {
    static func makeContiguousDays(from events: [CalendarCoreUI.UIEvent]) -> [PlanningDay] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.startDate)
        }

        let referenceDate = grouped.keys.min() ?? calendar.startOfDay(for: Date())
        let upperReferenceDate = grouped.keys.max() ?? referenceDate

        guard let firstWeek = calendar.dateInterval(of: .weekOfYear, for: referenceDate),
              let lastWeek = calendar.dateInterval(of: .weekOfYear, for: upperReferenceDate) else {
            return []
        }

        var days: [PlanningDay] = []
        var currentDate = firstWeek.start
        while currentDate < lastWeek.end {
            let dayStart = calendar.startOfDay(for: currentDate)
            let sortedEvents = (grouped[dayStart] ?? []).sorted {
                $0.startDate < $1.startDate
            }
            days.append(PlanningDay(date: dayStart, events: sortedEvents))

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return days
    }
}

extension PlanningDay {
    static let preview: [PlanningDay] = makeContiguousDays(from: UIEvent.random100Events)
}
