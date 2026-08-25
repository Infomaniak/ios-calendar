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

import CalendarCore
import Foundation
import MultiplatformCalendar
import SwiftUI

public extension UIEvent {
    struct Colors: Sendable, Equatable, Hashable {
        public let calendarSourceColor: Color
        public let containerColor: Color
        public let onContainerColor: Color
        public let containerVariantColor: Color
        public let onContainerVariantColor: Color

        public let sourceColorArgb: Int32

        public init(
            calendarSourceColor: Color,
            containerColor: Color,
            onContainerColor: Color,
            containerVariantColor: Color,
            onContainerVariantColor: Color
        ) {
            self.calendarSourceColor = calendarSourceColor
            self.containerColor = containerColor
            self.onContainerColor = onContainerColor
            self.containerVariantColor = containerVariantColor
            self.onContainerVariantColor = onContainerVariantColor
            sourceColorArgb = containerColor.cgColor?.argb ?? 0
        }

        public init(eventColors: EventColors) {
            calendarSourceColor = Color(argb: eventColors.calendarSourceColor)
            containerColor = Color(argb: eventColors.containerColor)
            onContainerColor = Color(eventColor: eventColors.onContainerColor)
            containerVariantColor = Color(argb: eventColors.containerVariantColor)
            onContainerVariantColor = Color(eventColor: eventColors.onContainerVariantColor)
            sourceColorArgb = eventColors.sourceColor
        }

        public static func == (lhs: UIEvent.Colors, rhs: UIEvent.Colors) -> Bool {
            lhs.sourceColorArgb == rhs.sourceColorArgb
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(sourceColorArgb)
        }
    }
}

public struct UIEvent: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let status: EventStatus?
    public let location: String?
    public let kMeetLink: String? = nil // TODO: Get it from Event

    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool

    public let calendarId: String
    public let alarms: [UIEventAlarm]

    public let user: UIAttendee?
    public let attendees: [UIAttendee]

    public let colors: UIEvent.Colors

    public init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        status: EventStatus?,
        location: String? = nil,
        calendarId: String,
        alarms: [UIEventAlarm] = [],
        user: UIAttendee? = nil,
        attendees: [UIAttendee],
        colors: UIEvent.Colors
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.status = status
        self.location = location
        self.calendarId = calendarId
        self.alarms = alarms
        self.user = user
        self.attendees = attendees
        self.colors = colors
    }
}

public extension UIEvent {
    init?(eventDaySlice: MultiplatformCalendar.EventDaySlice, userEmail: String?) {
        let event = eventDaySlice.event

        id = "\(eventDaySlice.position.index)-\(event.occurrenceIdValue)"
        title = event.title
        status = event.status
        location = event.location

        startDate = eventDaySlice.displayStartInstant().date
        endDate = eventDaySlice.displayEndInstant().date
        isAllDay = eventDaySlice.isAllDay

        calendarId = event.calendarIdValue

        alarms = event.alarms.map {
            UIEventAlarm(sdk: $0)
        }

        var user: UIAttendee?
        attendees = event.attendees.map {
            let uiAttendee = UIAttendee(attendee: $0)
            if uiAttendee.email == userEmail {
                user = uiAttendee
            }
            return uiAttendee
        }
        self.user = user

        colors = .init(eventColors: event.colors)
    }
}

// MARK: - Previews

public extension UIEvent {
    static let alarmsPreview = UIEvent(
        id: "0",
        title: "Event Title",
        startDate: Date().addingTimeInterval(3600),
        endDate: Date().addingTimeInterval(7200),
        status: .confirmed,
        location: "1 Infinite Loop, Cupertino",
        calendarId: "0",
        alarms: UIEventAlarm.previews,
        attendees: UIAttendee.previews,
        colors: .preview
    )

    static let preview = UIEvent(
        id: "0",
        title: "Event Title",
        startDate: Date().addingTimeInterval(3600),
        endDate: Date().addingTimeInterval(7200),
        status: .confirmed,
        location: "1 Infinite Loop",
        calendarId: "0",
        attendees: UIAttendee.previews,
        colors: .preview
    )

    static let shortPreview = UIEvent(
        id: "1",
        title: "Short Title With A Very Long Title But It's Okay Because We Want To Test The UI And See How It Looks With A Long Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 15),
        status: .confirmed,
        calendarId: "0",
        user: UIAttendee(displayName: "Tim Cook", email: "tim@apple.com", status: .accepted),
        attendees: UIAttendee.previews,
        colors: .preview
    )
    static let mediumPreview = UIEvent(
        id: "2",
        title: "Medium Title With A Very Long Title But It's Okay Because We Want To Test The UI And See How It Looks With A Long Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 2),
        status: .tentative,
        calendarId: "0",
        user: UIAttendee(displayName: "Tim Cook", email: "tim@apple.com", status: .needsAction),
        attendees: [],
        colors: .preview
    )
    static let longPreview = UIEvent(
        id: "3",
        title: "Long Title With A Very Long Title But It's Okay Because We Want To Test The UI And See How It Looks With A Long Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
        status: .cancelled,
        calendarId: "0",
        user: UIAttendee(displayName: "Tim Cook", email: "tim@apple.com", status: .declined),
        attendees: UIAttendee.previews,
        colors: .preview
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
            calendarId: "0",
            attendees: UIAttendee.previews,
            colors: .preview
        )
    }
}

public extension UIEvent.Colors {
    static let preview = UIEvent.Colors(
        calendarSourceColor: Color.purple,
        containerColor: Color.purple.opacity(0.2),
        onContainerColor: Color.purple,
        containerVariantColor: Color.purple.opacity(0.2),
        onContainerVariantColor: Color.purple.opacity(0.7)
    )
}
