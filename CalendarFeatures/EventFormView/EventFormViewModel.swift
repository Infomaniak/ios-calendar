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
import CalendarCoreUI
import Foundation
import InfomaniakDI
import MultiplatformCalendar
import Observation
import OSLog

@MainActor @Observable
final class EventFormViewModel {
    enum DatePickerId {
        case start
        case end
    }

    private(set) var availableCalendars = [UICalendar]()

    var draft: EventDraft
    private var originalDraft: EventDraft

    private let validator = EventDraftValidator()

    var validationErrors: Set<EventDraftValidator.ValidationError> {
        validator.validate(draft)
    }

    var isEdited: Bool {
        originalDraft != draft
    }

    init(editionMode: EditionMode) {
        let draft: EventDraft
        switch editionMode {
        case .new:
            draft = EventDraft.empty()
        case .editEvent(let origin, let calendar):
            draft = EventDraft.fromEvent(origin, calendar: calendar)
        case .editDraft(let existingDraft):
            draft = existingDraft
        }

        originalDraft = draft
        self.draft = draft
    }

    func createEvent() async throws {
        try await CreateEventUseCase().execute(draft: draft)
    }

    func updateTimeZone(_ timeZone: Foundation.TimeZone, for pickerId: DatePickerId, calendar: Foundation.Calendar) {
        let date = pickerId == .start ? draft.startDate : draft.endDate
        let oldTimeZone = pickerId == .start ? draft.startTimeZone : draft.endTimeZone

        guard oldTimeZone != timeZone else { return }

        var calendar = calendar
        calendar.timeZone = oldTimeZone ?? .current
        let components = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: date)
        calendar.timeZone = timeZone
        guard let updatedDate = calendar.date(from: components) else {
            Logger.view.error("Failed to preserve the local date when changing timezone")
            return
        }

        switch pickerId {
        case .start:
            if draft.startTimeZone == draft.endTimeZone {
                draft.startDate = updatedDate
                updateTimeZone(timeZone, for: .end, calendar: calendar)
            } else {
                updateStartDate(updatedDate)
            }
            draft.startTimeZone = timeZone
        case .end:
            draft.endDate = max(updatedDate, draft.startDate)
            draft.endTimeZone = timeZone
        }
    }

    func updateStartDate(_ date: Date) {
        if date > draft.endDate {
            let duration = draft.endDate.timeIntervalSince(draft.startDate)
            draft.endDate = date.addingTimeInterval(duration)
        }
        draft.startDate = date
    }

    func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            availableCalendars = calendars.map { UICalendar(calendar: $0) }.filter { $0.accessLevel.canWrite }

            if draft.calendarId == nil {
                let calendarId = availableCalendars.first?.id
                originalDraft.calendarId = calendarId
                draft.calendarId = calendarId
            }
        }
    }
}
