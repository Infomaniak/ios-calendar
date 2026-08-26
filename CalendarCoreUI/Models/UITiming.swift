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
import MultiplatformCalendar

public struct UITiming: Sendable, Hashable, Equatable {
    public let start: Date
    public let end: Date
    public let startTimeZone: TimeZone?
    public let endTimeZone: TimeZone?

    public init(start: Date, end: Date, startTimeZone: TimeZone? = nil, endTimeZone: TimeZone? = nil) {
        self.start = start
        self.end = end
        self.startTimeZone = startTimeZone
        self.endTimeZone = endTimeZone
    }

    public init(eventTiming: MultiplatformCalendar.EventTiming) {
        start = eventTiming.startInstantLocal().date
        end = eventTiming.endInstantLocal().date
        startTimeZone = eventTiming.startTimeZone.flatMap { TimeZone(identifier: $0.id) }
        endTimeZone = eventTiming.endTimeZone.flatMap { TimeZone(identifier: $0.id) }
    }
}

public extension UITiming {
    static let preview = UITiming(start: .now, end: .now.addingTimeInterval(3600))
}
