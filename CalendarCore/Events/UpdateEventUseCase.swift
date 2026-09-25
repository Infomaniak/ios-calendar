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

import InfomaniakDI
import MultiplatformCalendar

public struct UpdateEventUseCase: Sendable {
    public init() {}

    public func execute(
        occurrenceId: String,
        scope: RecurrenceScope,
        draft: EventDraft
    ) async throws {
        let errors = EventDraftValidator().validate(draft)
        guard errors.isEmpty else {
            throw EventDraftValidator.ValidationErrors(errors: errors)
        }

        @InjectService var calendarSDK: CalendarCoreGraph
        let id = OccurrenceId.companion.parse(value: occurrenceId)
        guard let occurrence = try await calendarSDK.calendarManager.getOccurrence(occurrenceId: id),
              let originalData = try await calendarSDK.calendarManager.getEditData(occurrenceId: id) else {
            throw CalendarError.eventOccurrenceNotFound
        }

        let target = occurrence.targetedAs(scope: scope)
        try await calendarSDK.calendarManager.updateEvent(
            target: target,
            data: draft.toEventEditData(preserving: originalData)
        )
    }
}
