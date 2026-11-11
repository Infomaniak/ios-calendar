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

import AppIntents
import Foundation
import InfomaniakDI
import MultiplatformCalendar

@available(iOS 27.0, *)
@AppEntity(schema: .calendar.event)
public struct EventEntity: IndexedEntity, Sendable {
    public static let defaultQuery = EventEntityQuery()

    public let id: String

    public var calendar: CalendarEntity
    public var title: String
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var recurrence: Foundation.Calendar.RecurrenceRule?
    public var note: AttributedString?
    public var travelTime: Duration?
    public var location: EventEntityLocation?
    public var virtualLocation: URL?
    public var status: EventEntityStatus?
    public var alarms: [EventEntityAlarm]
    public var organizers: [IntentPerson]
    public var attendees: [AttendeeEntity]

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(startDate.formatted(date: .abbreviated, time: isAllDay ? .omitted : .shortened))"
        )
    }

    public init(
        id: String,
        calendar: CalendarEntity,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        recurrence: Foundation.Calendar.RecurrenceRule? = nil,
        note: AttributedString? = nil,
        travelTime: Duration? = nil,
        location: EventEntityLocation? = nil,
        virtualLocation: URL? = nil,
        status: EventEntityStatus? = nil,
        alarms: [EventEntityAlarm] = [],
        organizers: [IntentPerson] = [],
        attendees: [AttendeeEntity] = []
    ) {
        self.id = id
        self.calendar = calendar
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.recurrence = recurrence
        self.note = note
        self.travelTime = travelTime
        self.location = location
        self.virtualLocation = virtualLocation
        self.status = status
        self.alarms = alarms
        self.organizers = organizers
        self.attendees = attendees
    }

    public struct EventEntityQuery: EntityQuery {
        public init() {}

        public func entities(for identifiers: [EventEntity.ID]) async throws -> [EventEntity] {
            @InjectService var calendarSDK: CalendarCoreGraph
            let calendars = await calendarSDK.calendarManager.flatCalendars()
            let calendarsById = Dictionary(calendars.map { ($0.idValue, $0) }) { first, _ in first }

            var entities = [EventEntity]()
            for identifier in identifiers {
                let occurrenceId = OccurrenceId.companion.parse(value: identifier)
                guard let event = try await calendarSDK.calendarManager.getOccurrence(occurrenceId: occurrenceId),
                      let calendar = calendarsById[event.calendarIdValue] else { continue }

                entities.append(EventEntity(event: event, calendar: CalendarEntity(calendar: calendar)))
            }

            return entities
        }
    }
}

@available(iOS 27.0, *)
public extension EventEntity {
    init(event: Event, calendar: CalendarEntity) {
        id = event.occurrenceIdValue
        self.calendar = calendar
        title = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        startDate = event.timing.startInstantLocal().toNSDate()
        endDate = event.timing.endInstantLocal().toNSDate()
        isAllDay = event.timing.isAllDay
        // The KMP recurrence rule is not mapped yet.
        recurrence = nil

        if let description = event.description_, !description.isEmpty {
            note = AttributedString(description)
        } else {
            note = nil
        }

        travelTime = nil

        switch onEnum(of: event.location) {
        case .place(let place):
            location = .address(place.text)
        case .bookableRoom(let room):
            if let name = room.resource?.name {
                location = .address(name)
            } else {
                location = nil
            }
        default:
            location = nil
        }

        if let meetRoomUrl = event.meetRoomUrl {
            virtualLocation = URL(string: meetRoomUrl)
        } else {
            virtualLocation = nil
        }

        if let eventStatus = event.status {
            status = EventEntityStatus(eventStatus: eventStatus)
        } else {
            status = nil
        }

        let endDate = endDate
        alarms = event.alarms.map { EventEntityAlarm(trigger: UIAlarmTrigger(alarmTrigger: $0.trigger), endDate: endDate) }

        if let organizer = event.organizer {
            organizers = [IntentPerson(email: organizer.email, displayName: organizer.displayName)]
        } else {
            organizers = []
        }

        attendees = event.attendees.map { AttendeeEntity(attendee: $0) }
    }
}
