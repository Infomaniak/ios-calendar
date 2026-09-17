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

/// A fixed range of calendar periods with cheap identities and dates calculated only when needed.
struct CalendarPeriodCollection: RandomAccessCollection {
    struct Period: Identifiable {
        let id: Int
        fileprivate let origin: Date
        fileprivate let calendar: Calendar
        fileprivate let component: Calendar.Component

        var date: Date {
            guard let date = calendar.date(byAdding: component, value: id, to: origin) else {
                preconditionFailure("The period offset must represent a valid calendar date")
            }
            return date
        }
    }

    let origin: Date
    private let calendar: Calendar
    private let component: Calendar.Component
    let indices: Range<Int>

    var startIndex: Int {
        indices.lowerBound
    }

    var endIndex: Int {
        indices.upperBound
    }

    init(calendar: Calendar, component: Calendar.Component, origin: Date, indices: Range<Int>) {
        precondition([.day, .weekOfYear, .month].contains(component))
        guard let start = calendar.dateInterval(of: component, for: origin)?.start else {
            preconditionFailure("The origin must represent a valid calendar period")
        }
        self.origin = start
        self.calendar = calendar
        self.component = component
        self.indices = indices
    }

    subscript(position: Int) -> Period {
        precondition(indices.contains(position))
        return Period(id: position, origin: origin, calendar: calendar, component: component)
    }

    func index(after i: Int) -> Int {
        i + 1
    }

    func index(before i: Int) -> Int {
        i - 1
    }

    func index(_ i: Int, offsetBy distance: Int) -> Int {
        i + distance
    }

    func distance(from start: Int, to end: Int) -> Int {
        end - start
    }

    func index(for date: Date) -> Int? {
        guard let start = calendar.dateInterval(of: component, for: date)?.start,
              let offset = calendar.dateComponents([component], from: origin, to: start).value(for: component) else {
            preconditionFailure("The date must represent a valid calendar period")
        }
        return indices.contains(offset) ? offset : nil
    }
}
