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

/// Describes how `MultipleDaysView` groups and scrolls its day columns.
enum MultipleDaysLayout: Hashable {
    /// Displays every day of a calendar period on a single page (e.g. a week) and scrolls page by page.
    case paged(Calendar.Component)
    /// Displays `visibleDays` days next to each other and scrolls day by day.
    case continuous(visibleDays: Int)

    static let week = MultipleDaysLayout.paged(.weekOfYear)
    static let threeDays = MultipleDaysLayout.continuous(visibleDays: 3)

    /// Calendar component represented by one element of the pager.
    var pagerComponent: Calendar.Component {
        switch self {
        case .paged(let component):
            return component
        case .continuous:
            return .day
        }
    }

    /// Number of pager elements visible at once.
    var pagerViewCount: Int {
        switch self {
        case .paged:
            return 1
        case .continuous(let visibleDays):
            return max(visibleDays, 1)
        }
    }

    var pagerScrollBehavior: CalendarPeriodPagerScrollBehavior {
        switch self {
        case .paged:
            return .paging
        case .continuous:
            return .viewAligned
        }
    }

    var pagerOffsets: Range<Int> {
        switch pagerComponent {
        case .weekOfYear, .weekOfMonth:
            return -5218 ..< 5219
        case .month:
            return -1200 ..< 1201
        default:
            return -36525 ..< 36526
        }
    }

    /// Start of the pager element containing `date`.
    func pagerDate(for date: Date, calendar: Calendar) -> Date {
        return calendar.dateInterval(of: pagerComponent, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// Days displayed by the pager element starting at `pagerDate`.
    func pageDates(for pagerDate: Date, calendar: Calendar) -> [Date] {
        switch self {
        case .paged(let component):
            guard let interval = calendar.dateInterval(of: component, for: pagerDate) else { return [] }
            return calendar.days(from: interval.start, to: interval.end)
        case .continuous:
            return [calendar.startOfDay(for: pagerDate)]
        }
    }

    /// Days visible on screen when `selectedDate` is selected.
    func visibleInterval(for selectedDate: Date, calendar: Calendar) -> DateInterval? {
        switch self {
        case .paged(let component):
            return calendar.dateInterval(of: component, for: selectedDate)
        case .continuous:
            let start = calendar.startOfDay(for: selectedDate)
            guard let end = calendar.date(byAdding: .day, value: pagerViewCount, to: start) else { return nil }
            return DateInterval(start: start, end: end)
        }
    }

    /// Visible days extended by the amount of days that can be revealed by one scroll gesture on each side.
    func preloadedInterval(for selectedDate: Date, calendar: Calendar) -> DateInterval? {
        guard let visibleInterval = visibleInterval(for: selectedDate, calendar: calendar) else { return nil }

        let component: Calendar.Component
        let value: Int
        switch self {
        case .paged(let pagedComponent):
            component = pagedComponent
            value = 1
        case .continuous:
            component = .day
            value = pagerViewCount
        }

        guard let start = calendar.date(byAdding: component, value: -value, to: visibleInterval.start),
              let end = calendar.date(byAdding: component, value: value, to: visibleInterval.end) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }

    /// Whether today is the selected day of a continuous layout or belongs to the selected period of a paged one.
    func isSelectingToday(_ selectedDate: Date, calendar: Calendar) -> Bool {
        return calendar.isDate(selectedDate, equalTo: .now, toGranularity: pagerComponent)
    }
}

private extension Calendar {
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
}
