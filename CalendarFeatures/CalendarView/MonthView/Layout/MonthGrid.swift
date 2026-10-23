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

import Foundation

struct MonthGrid: Hashable {
    let monthInterval: DateInterval
    let interval: DateInterval
    let weeks: [[Date]]

    init?(month: Date, calendar: Calendar) {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let gridStart = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)?.start,
              let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let gridEnd = calendar.dateInterval(of: .weekOfYear, for: lastDayOfMonth)?.end
        else { return nil }

        var weeks = [[Date]]()
        var weekStart = gridStart
        while weekStart < gridEnd, let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) {
            weeks.append(calendar.days(from: weekInterval.start, to: weekInterval.end))
            weekStart = weekInterval.end
        }

        self.monthInterval = monthInterval
        interval = DateInterval(start: gridStart, end: gridEnd)
        self.weeks = weeks
    }

    func isInMonth(_ day: Date) -> Bool {
        return day >= monthInterval.start && day < monthInterval.end
    }
}

extension Calendar {
    func days(from start: Date, to end: Date) -> [Date] {
        var days = [Date]()
        var currentDay = startOfDay(for: start)
        while currentDay < end {
            days.append(currentDay)
            guard let nextDay = date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }
        return days
    }

    var orderedWeekdayIndices: [Int] {
        let weekdayCount = weekdaySymbols.count
        let firstWeekdayIndex = firstWeekday - 1
        guard (0 ..< weekdayCount).contains(firstWeekdayIndex) else {
            return Array(0 ..< weekdayCount)
        }
        return (0 ..< weekdayCount).map { ($0 + firstWeekdayIndex) % weekdayCount }
    }
}
