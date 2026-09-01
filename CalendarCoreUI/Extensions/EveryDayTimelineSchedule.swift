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
import SwiftUI

public struct EveryDayTimelineSchedule: TimelineSchedule, Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    public func entries(from startDate: Date, mode: Mode) -> Entries {
        Entries(calendar: calendar, startDate: startDate)
    }

    public struct Entries: Sequence, IteratorProtocol {
        private let calendar: Calendar

        private var date: Date?

        init(calendar: Calendar, startDate: Date) {
            self.calendar = calendar
            date = startDate
        }

        public mutating func next() -> Date? {
            guard let currentDate = date else { return nil }

            date = calendar.nextDate(
                after: currentDate,
                matching: DateComponents(hour: 0, minute: 0, second: 0),
                matchingPolicy: .nextTime
            )
            return currentDate
        }
    }
}

public extension TimelineSchedule where Self == EveryDayTimelineSchedule {
    static var everyDay: EveryDayTimelineSchedule {
        EveryDayTimelineSchedule()
    }
}
