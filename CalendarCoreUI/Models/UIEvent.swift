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
import KmpCalendar

extension Kotlinx_datetimeLocalDateTime {
    var date: Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month.ordinal)
        components.day = Int(day)
        components.hour = Int(hour)
        components.minute = Int(minute)
        components.second = Int(second)
        return calendar.date(from: components)
    }
}

public struct UIEvent: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let startDate: Date?
    public let endDate: Date?

    public init(id: String, title: String, startDate: Date?, endDate: Date?) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
    }
}

public extension UIEvent {
    init(event: KmpCalendar.Event) {
        id = event.idValue
        title = event.title
        startDate = event.start?.date
        endDate = event.end?.date
    }
}

public extension UIEvent {
    static let preview = UIEvent(id: "0", title: "Event Title", startDate: Date(), endDate: Date().addingTimeInterval(3600))

    static let random100Events: [UIEvent] = (0 ..< 100).map { index in
        let dayRangeInSeconds = 30 * 24 * 3600
        let randomStartDate = Date().addingTimeInterval(TimeInterval(Int.random(in: -dayRangeInSeconds ... dayRangeInSeconds)))
        let randomEndDate = randomStartDate.addingTimeInterval(Double.random(in: 3600 ... 7200))
        return UIEvent(id: "\(index)", title: "Event \(index)", startDate: randomStartDate, endDate: randomEndDate)
    }
}
