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

public struct UIEventSummary: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let occurrenceId: String
    public let title: String
    public let location: String?
    public let status: EventStatus?
    public let colors: UIEventColor
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let hasAttendees: Bool
    public let hasMeetRoom: Bool
    public let myStatus: UIParticipationStatus?

    public var displayTitle: AttributedString {
        guard title.isEmpty else { return AttributedString(title) }
        var label = AttributedString(CalendarResourcesStrings.eventUntitledLabel)
        label.inlinePresentationIntent = .emphasized
        return label
    }

    public init(eventDaySlice: EventDaySlice) {
        let event = eventDaySlice.event
        self.init(
            event: event,
            id: "\(eventDaySlice.position.index)-\(event.occurrenceIdValue)",
            startDate: eventDaySlice.displayStartInstant().toNSDate(),
            endDate: eventDaySlice.displayEndInstant().toNSDate(),
            isAllDay: eventDaySlice.isAllDay
        )
    }

    public init(event: EventSummary) {
        self.init(
            event: event,
            id: event.occurrenceIdValue,
            startDate: event.timing.startInstantLocal().toNSDate(),
            endDate: event.timing.endInstantLocal().toNSDate(),
            isAllDay: event.timing.isAllDay
        )
    }

    private init(event: EventSummary, id: String, startDate: Date, endDate: Date, isAllDay: Bool) {
        self.id = id
        occurrenceId = event.occurrenceIdValue
        title = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        location = event.location.flatMap { $0.isEmpty ? nil : $0 }
        status = event.status
        colors = UIEventColor(eventColors: event.colors)

        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        hasAttendees = event.hasAttendees
        hasMeetRoom = false
        if let status = event.myStatus {
            myStatus = UIParticipationStatus(participationStatus: status)
        } else {
            myStatus = nil
        }
    }

    private init(details: UIEventDetails) {
        id = details.id
        occurrenceId = details.occurrenceId
        title = details.title
        location = details.location
        status = details.status
        colors = details.colors
        startDate = details.startDate
        endDate = details.endDate
        isAllDay = details.isAllDay
        hasAttendees = !details.attendees.isEmpty
        hasMeetRoom = details.kMeetLink != nil
        myStatus = details.user?.status
    }
}

public extension UIEventSummary {
    static let preview = UIEventSummary(details: .preview)
    static let shortPreview = UIEventSummary(details: .shortPreview)
    static let mediumPreview = UIEventSummary(details: .mediumPreview)
    static let longPreview = UIEventSummary(details: .longPreview)
    static let random100Events = UIEventDetails.random100Events.map { UIEventSummary(details: $0) }
}
