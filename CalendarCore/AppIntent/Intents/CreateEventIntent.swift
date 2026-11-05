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

@available(iOS 27.0, *)
@AppIntent(schema: .calendar.createEvent)
public struct CreateEventIntent {
    public var title: String
    public var startDate: Date
    public var endDate: Date?
    public var location: EventEntityLocation?
    public var calendar: CalendarEntity
    public var isAllDay: Bool
    public var recurrence: Foundation.Calendar.RecurrenceRule?
    public var attendees: [AttendeeEntity]
    public var note: AttributedString?

    public init() {}

    public func perform() async throws -> some ReturnsValue<EventEntity> {
        let defaultEndDate = isAllDay
            ? startDate
            : startDate.addingTimeInterval(UserDefaults.shared.defaultEventDuration.timeInterval)

        let draft = EventDraft(
            calendarId: calendar.id,
            title: title,
            description: note.map { String($0.characters) } ?? "",
            allDay: isAllDay,
            startDate: startDate,
            endDate: endDate ?? defaultEndDate
        )
        try await CreateEventUseCase().execute(draft: draft)

        return .result(value: createdEvent(draft: draft))
    }

    // TODO: Return the created event once CreateEventUseCase provides its occurrence ID.
    private func createdEvent(draft: EventDraft) -> EventEntity {
        return EventEntity(
            id: UUID().uuidString,
            calendar: calendar,
            title: draft.title,
            startDate: draft.startDate,
            endDate: draft.endDate,
            isAllDay: draft.allDay,
            note: note
        )
    }
}
