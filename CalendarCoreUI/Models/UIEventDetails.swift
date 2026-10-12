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

import CalendarResources
import Foundation
import MultiplatformCalendar
import SwiftUI

public struct UIEventDetails: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let occurrenceId: String
    public let calendarId: String

    public let title: String
    public let description: String?
    public let status: EventStatus?
    public let location: String?
    public let kMeetLink: URL?
    public let colors: UIEventColor
    public let classification: UIClassification?
    public let canEdit: Bool
    public let isOccurrence: Bool

    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let timing: UITiming

    public let alarms: [UIEventAlarm]

    public let user: UIAttendee?
    public let attendees: [UIAttendee]
    public let organizer: UIOrganizer?

    public var displayTitle: AttributedString {
        guard title.isEmpty else {
            return AttributedString(title)
        }

        var untitledLabel = AttributedString(CalendarResourcesStrings.eventUntitledLabel)
        untitledLabel.inlinePresentationIntent = .emphasized
        return untitledLabel
    }

    public init(
        id: String,
        occurrenceId: String,
        title: String,
        description: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        status: EventStatus?,
        location: String? = nil,
        kMeetLink: URL? = nil,
        calendarId: String,
        alarms: [UIEventAlarm] = [],
        user: UIAttendee? = nil,
        attendees: [UIAttendee],
        organizer: UIOrganizer? = nil,
        colors: UIEventColor,
        classification: UIClassification? = .public,
        timing: UITiming,
        canEdit: Bool,
        isOccurrence: Bool = false
    ) {
        self.id = id
        self.occurrenceId = occurrenceId
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.status = status
        self.location = location
        self.kMeetLink = kMeetLink
        self.calendarId = calendarId
        self.alarms = alarms
        self.user = user
        self.attendees = attendees
        self.organizer = organizer
        self.colors = colors
        self.classification = classification
        self.timing = timing
        self.canEdit = canEdit
        self.isOccurrence = isOccurrence
    }
}

public extension UIEventDetails {
    init(event: MultiplatformCalendar.Event, userEmail: String?) {
        id = event.occurrenceIdValue
        occurrenceId = event.occurrenceIdValue
        calendarId = event.calendarIdValue

        title = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        description = event.description_
        status = event.status
        kMeetLink = event.meetRoomUrl.flatMap { URL(string: $0) }

        if let location = event.location, !location.isEmpty {
            self.location = location
        } else {
            location = nil
        }

        startDate = event.timing.startInstantLocal().toNSDate()
        endDate = event.timing.endInstantLocal().toNSDate()
        isAllDay = event.timing.isAllDay
        timing = UITiming(eventTiming: event.timing)

        alarms = event.alarms.map {
            UIEventAlarm(sdk: $0)
        }

        var user: UIAttendee?
        attendees = event.attendees.map {
            let uiAttendee = UIAttendee(attendee: $0)
            if uiAttendee.email == userEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                user = uiAttendee
            }
            return uiAttendee
        }
        self.user = user
        organizer = event.organizer.map { UIOrganizer(organizer: $0) }

        colors = .init(eventColors: event.colors)

        classification = .init(classification: event.classification)

        canEdit = event.canEdit
        isOccurrence = event.isOccurrence
    }
}

// MARK: - Previews

public extension UIEventDetails {
    static let alarmsPreview = UIEventDetails(
        id: "0",
        occurrenceId: "0",
        title: "Event Title",
        startDate: Date().addingTimeInterval(3600),
        endDate: Date().addingTimeInterval(7200),
        status: .confirmed,
        location: "1 Infinite Loop, Cupertino",
        calendarId: "0",
        alarms: UIEventAlarm.previews,
        attendees: UIAttendee.previews,
        colors: .preview,
        timing: .preview,
        canEdit: true
    )

    static let preview = UIEventDetails(
        id: "0",
        occurrenceId: "1",
        title: "Event Title",
        startDate: Date().addingTimeInterval(3600),
        endDate: Date().addingTimeInterval(7200),
        status: .confirmed,
        location: "1 Infinite Loop",
        calendarId: "0",
        attendees: UIAttendee.previews,
        colors: .preview,
        timing: .preview,
        canEdit: true
    )

    static let shortPreview = UIEventDetails(
        id: "1",
        occurrenceId: "1",
        title: "Short Title With A Very Long Title But It's Okay Because We Want To Test The UI And See How It Looks With A Long Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 15),
        status: .confirmed,
        calendarId: "0",
        user: UIAttendee(displayName: "Tim Cook", email: "tim@apple.com", status: .accepted),
        attendees: UIAttendee.previews,
        colors: .preview,
        timing: .preview,
        canEdit: true
    )
    static let mediumPreview = UIEventDetails(
        id: "2",
        occurrenceId: "2",
        title: "Medium Title With A Very Long Title But It's Okay Because We Want To Test The UI And See How It Looks With A Long Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 2),
        status: .tentative,
        calendarId: "0",
        user: UIAttendee(displayName: "Tim Cook", email: "tim@apple.com", status: .needsAction),
        attendees: [],
        colors: .preview,
        timing: .preview,
        canEdit: true
    )
    static let longPreview = UIEventDetails(
        id: "3",
        occurrenceId: "3",
        title: "Long Title With A Very Long Title But It's Okay Because We Want To Test The UI And See How It Looks With A Long Title",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
        status: .cancelled,
        calendarId: "0",
        user: UIAttendee(displayName: "Tim Cook", email: "tim@apple.com", status: .declined),
        attendees: UIAttendee.previews,
        colors: .preview,
        timing: .preview,
        canEdit: true
    )

    static let random100Events: [UIEventDetails] = (0 ..< 100).map { index in
        let dayRangeInSeconds = 30 * 24 * 3600
        let randomStartDate = Date().addingTimeInterval(TimeInterval(Int.random(in: -dayRangeInSeconds ... dayRangeInSeconds)))
        let randomEndDate = randomStartDate.addingTimeInterval(Double.random(in: 3600 ... 7200))
        return UIEventDetails(
            id: "\(index)",
            occurrenceId: "\(index)",
            title: "Event \(index)",
            startDate: randomStartDate,
            endDate: randomEndDate,
            status: .confirmed,
            calendarId: "0",
            attendees: UIAttendee.previews,
            colors: .preview,
            timing: .preview,
            canEdit: true
        )
    }
}
