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
@AppIntent(schema: .calendar.updateEvent)
public struct UpdateEventIntent {
    public var event: EventEntity
    public var title: String?
    public var attendees: [AttendeeEntity]?
    public var startDate: Date?
    public var endDate: Date?
    public var isAllDay: Bool?
    public var calendar: CalendarEntity?
    public var recurrence: Foundation.Calendar.RecurrenceRule?
    public var note: String?
    public var location: EventEntityLocation?
    public var span: EventSpan?

    public init() {}

    public func perform() async throws -> some ReturnsValue<EventEntity> {
        @InjectService var calendarSDK: CalendarCoreGraph
        let occurrenceId = OccurrenceId.companion.parse(value: event.id)
        guard let occurrence = try await calendarSDK.calendarManager.getOccurrence(occurrenceId: occurrenceId),
              let editData = try await calendarSDK.calendarManager.getEditData(occurrenceId: occurrenceId) else {
            throw CalendarError.eventOccurrenceNotFound
        }

        let editionDraft = createEditionDraft(occurrence: occurrence, editData: editData)

        try await UpdateEventUseCase().execute(
            occurrenceId: event.id,
            scope: (span ?? .this).recurrenceScope,
            draft: editionDraft
        )

        let updatedEvent = try await EventEntity.defaultQuery.entities(for: [event.id]).first
        return .result(value: updatedEvent ?? event)
    }

    private func createEditionDraft(occurrence: Event, editData: EventEditData) -> EventDraft {
        var draft = EventDraft(event: occurrence, editData: editData)
        if let title {
            draft.title = title
        }
        if let note {
            draft.description = note
        }
        if let isAllDay {
            draft.allDay = isAllDay
        }
        if let startDate {
            let duration = draft.endDate.timeIntervalSince(draft.startDate)
            draft.startDate = startDate
            draft.endDate = startDate.addingTimeInterval(duration)
        }
        if let endDate {
            draft.endDate = endDate
        }
        if let calendar {
            draft.calendarId = calendar.id
        }

        return draft
    }
}
