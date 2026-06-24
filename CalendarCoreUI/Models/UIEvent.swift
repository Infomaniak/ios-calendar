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

extension KotlinInstant {
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(toEpochMilliseconds()) / 1000.0)
    }
}

public enum UIEventStatus: String, Sendable, Equatable {
    case confirmed = "CONFIRMED"
    case tentative = "TENTATIVE"
    case cancelled = "CANCELLED"
}

public struct UIEvent: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let status: UIEventStatus?

    public let user: UIAttendee?
    public let attendees: [UIAttendee]

    public init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        status: UIEventStatus?,
        user: UIAttendee? = nil,
        attendees: [UIAttendee]
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.user = user
        self.attendees = attendees
    }
}

public extension UIEvent {
    init?(event: KmpCalendar.Event, userEmail: String?) {
        id = event.idValue
        title = event.title
        status = UIEventStatus(rawValue: event.status ?? "")

        var user: UIAttendee?
        self.attendees = event.attendees.map {
            let uiAttendee = UIAttendee(attendee: $0)
            if uiAttendee.email == userEmail {
                user = uiAttendee
            }
            return uiAttendee
        }
        self.user = user

        switch event.timing {
        case let timed as EventTimingTimed:
            startDate = timed.start.date
            endDate = timed.end.date
        default:
            return nil
        }
    }
}

public extension UIEvent {
    static let preview = UIEvent(
        id: "0",
        title: "Event Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        status: .confirmed,
        attendees: UIAttendee.previews
    )

    static let shortPreview = UIEvent(
        id: "1",
        title: "Short Title With A Very Long Title But It's Okay Because We Want To Test The UI And See How It Looks With A Long Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 15),
        status: .confirmed,
        attendees: UIAttendee.previews
    )
    static let mediumPreview = UIEvent(
        id: "2",
        title: "Medium Title With A Very Long Title But It's Okay Because We Want To Test The UI And See How It Looks With A Long Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 2),
        status: .tentative,
        attendees: []
    )
    static let longPreview = UIEvent(
        id: "3",
        title: "Long Title With A Very Long Title But It's Okay Because We Want To Test The UI And See How It Looks With A Long Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
        status: .cancelled,
        attendees: UIAttendee.previews
    )

    static let random100Events: [UIEvent] = (0 ..< 100).map { index in
        let dayRangeInSeconds = 30 * 24 * 3600
        let randomStartDate = Date().addingTimeInterval(TimeInterval(Int.random(in: -dayRangeInSeconds ... dayRangeInSeconds)))
        let randomEndDate = randomStartDate.addingTimeInterval(Double.random(in: 3600 ... 7200))
        return UIEvent(
            id: "\(index)",
            title: "Event \(index)",
            startDate: randomStartDate,
            endDate: randomEndDate,
            status: .confirmed,
            attendees: UIAttendee.previews
        )
    }
}
