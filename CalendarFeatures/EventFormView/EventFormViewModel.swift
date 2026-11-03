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

        var dateKeyPath: WritableKeyPath<EventDraft, Date> {
            switch self {
            case .start: \.startDate
            case .end: \.endDate
            }
        }

        var timeZoneKeyPath: WritableKeyPath<EventDraft, Foundation.TimeZone?> {
            switch self {
            case .start: \.startTimeZone
            case .end: \.endTimeZone
            }
        }
    }

    enum EditFormAction {
        case new
        case editDraft(occurrenceId: String, scope: RecurrenceScope)
    }

    private(set) var availableCalendars = [UICalendar]()

    var draft: EventDraft
    private var originalDraft: EventDraft
    let editionMode: EditionMode

    private let validator = EventDraftValidator()
    private let userDefaults: UserDefaults

    var validationErrors: Set<EventDraftValidator.ValidationError> {
        validator.validate(draft)
    }

    var isEdited: Bool {
        originalDraft != draft
    }

    private var currentDuration: TimeInterval {
        max(draft.endDate.timeIntervalSince(draft.startDate), 0)
    }

    init(editionMode: EditionMode, userDefaults: UserDefaults) {
        self.editionMode = editionMode
        self.userDefaults = userDefaults
        let draft: EventDraft
        switch editionMode {
        case .new(let selectedDate):
            draft = EventDraft.new(selectedDate: selectedDate)
        case .editDraft(let existingDraft, _):
            draft = existingDraft
        }

        originalDraft = draft
        self.draft = draft
    }

    func saveEvent(action: EditFormAction) async throws {
        switch action {
        case .new:
            try await CreateEventUseCase().execute(draft: draft)
        case .editDraft(let occurrenceId, let scope):
            try await UpdateEventUseCase().execute(
                occurrenceId: occurrenceId,
                scope: scope,
                draft: draft
            )
        }
        userDefaults.lastSelectedCalendarId = draft.calendarId
    }

    func setDate(_ date: Date, for pickerId: DatePickerId) {
        let duration = currentDuration
        draft[keyPath: pickerId.dateKeyPath] = date
        fixInterval(keeping: pickerId, duration: duration)
    }

    private func fixInterval(keeping pickerId: DatePickerId, duration: TimeInterval) {
        guard draft.startDate > draft.endDate else { return }

        switch pickerId {
        case .start:
            draft.endDate = draft.startDate.addingTimeInterval(duration)
        case .end:
            draft.startDate = draft.endDate.addingTimeInterval(-duration)
        }
    }

    func setTimeZone(_ timeZone: Foundation.TimeZone, for pickerId: DatePickerId, calendar: Foundation.Calendar) {
        let oldTimeZone = draft[keyPath: pickerId.timeZoneKeyPath]
        guard oldTimeZone != timeZone else { return }

        let duration = currentDuration
        let isSharedTimeZone = draft.startTimeZone == draft.endTimeZone
        let editedPickerIds: [DatePickerId] = pickerId == .start && isSharedTimeZone ? [.start, .end] : [pickerId]

        for editedPickerId in editedPickerIds {
            draft[keyPath: editedPickerId.dateKeyPath] = draft[keyPath: editedPickerId.dateKeyPath].keepingLocalTime(
                from: oldTimeZone ?? .current,
                to: timeZone,
                calendar: calendar
            )
            draft[keyPath: editedPickerId.timeZoneKeyPath] = timeZone
        }
        fixInterval(keeping: pickerId, duration: duration)
    }

    func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await sections in calendarSDK.calendarManager.observeCalendars() {
            let calendars = sections.flatMap { $0.calendars }
            updateAvailableCalendars(calendars.map { UICalendar(calendar: $0) })
        }
    }

    func updateAvailableCalendars(_ calendars: [UICalendar]) {
        availableCalendars = calendars.filter { $0.accessLevel.canWrite }

        guard case .new = editionMode else { return }
        guard draft.calendarId == nil || !availableCalendars.contains(where: { $0.id == draft.calendarId }) else { return }
        let calendarId = availableCalendars.first { $0.id == userDefaults.lastSelectedCalendarId }?.id
            ?? availableCalendars.first?.id
        if draft.calendarId == originalDraft.calendarId {
            originalDraft.calendarId = calendarId
        }
        draft.calendarId = calendarId
    }
}

private extension Date {
    func keepingLocalTime(
        from oldTimeZone: Foundation.TimeZone,
        to newTimeZone: Foundation.TimeZone,
        calendar: Foundation.Calendar
    ) -> Date {
        var calendar = calendar
        calendar.timeZone = oldTimeZone
        let components = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: self)
        calendar.timeZone = newTimeZone
        guard let date = calendar.date(from: components) else {
            return self
        }
        return date
    }
}
