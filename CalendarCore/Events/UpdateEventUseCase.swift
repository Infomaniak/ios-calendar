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

    public func execute(eventId: String, draft: EventDraft, originalData: EventEditData) async throws {
        let errors = EventDraftValidator().validate(draft)
        guard errors.isEmpty else {
            throw EventDraftValidator.ValidationErrors(errors: errors)
        }

        @InjectService var calendarSDK: CalendarCoreGraph
        try await calendarSDK.calendarManager.updateEvent(
            eventId: eventId,
            data: draft.toEventEditData(preserving: originalData)
        )
    }
}
