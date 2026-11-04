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
import InfomaniakCore
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

    private(set) var calendarSections = [UICalendarSection]()
    private var calendarsById = [String: UICalendar]()

    var draft: EventDraft
    private var originalDraft: EventDraft

    let editionMode: EditionMode

    var validationErrors: Set<EventDraftValidator.ValidationError> {
        EventDraftValidator().validate(draft)
    }

    var isEdited: Bool {
        originalDraft != draft
    }

    var selectedCalendar: UICalendar? {
        return calendar(withId: draft.calendarId)
    }

    var locationAvailabilityRequest: LocationAvailabilityRequest? {
        guard let calendar = selectedCalendar else { return nil }
        return LocationAvailabilityRequest(accountId: Int64(calendar.accountId), draft: draft)
    }

    var isRecurrenceEdited: Bool {
        originalDraft.recurrence != draft.recurrence
    }

    private var currentDuration: TimeInterval {
        return max(draft.endDate.timeIntervalSince(draft.startDate), 0)
    }

    init(editionMode: EditionMode) {
        self.editionMode = editionMode

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

        UserDefaults.shared.lastSelectedCalendarId = draft.calendarId
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

    @concurrent
    func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await sections in calendarSDK.calendarManager.observeCalendars() {
            await updateCalendarSections(sections.map { UICalendarSection(section: $0) })
        }
    }

    @concurrent
    func updateCalendarSections(_ sections: [UICalendarSection]) async {
        var updatedSections = [UICalendarSection]()
        var updatedCalendarsById = [String: UICalendar]()
        for section in sections {
            let writableCalendars = section.calendars.filter { $0.accessLevel.canWrite }
            guard !writableCalendars.isEmpty else { continue }

            updatedSections.append(UICalendarSection(
                accountId: section.accountId,
                organisationId: section.organisationId,
                organisationName: section.organisationName,
                calendars: writableCalendars
            ))
            for calendar in writableCalendars {
                updatedCalendarsById[calendar.id] = calendar
            }
        }

        await MainActor.run {
            guard !Task.isCancelled else { return }
            calendarSections = updatedSections
            calendarsById = updatedCalendarsById

            selectDraftDefaultCalendarIfNecessary()
        }
    }

    private func selectDraftDefaultCalendarIfNecessary() {
        guard case .new = editionMode, selectedCalendar == nil else {
            return
        }

        let calendar = calendar(withId: UserDefaults.shared.lastSelectedCalendarId) ?? calendarSections.first?.calendars.first
        let calendarId = calendar?.id

        if draft.calendarId == originalDraft.calendarId {
            originalDraft.calendarId = calendarId
        }
        draft.calendarId = calendarId
    }

    private func calendar(withId calendarId: String?) -> UICalendar? {
        guard let calendarId else { return nil }
        return calendarsById[calendarId]
    }

    func currentUser(in calendarAccounts: [CalendarAccount.ID: CalendarAccount]) -> UserProfile? {
        guard let calendar = selectedCalendar else { return nil }
        return calendarAccounts[calendar.accountId]?.user
    }

    func updateOrganizerForSelectedCalendar(calendarAccounts: [CalendarAccount.ID: CalendarAccount]) {
        guard case .new = editionMode else {
            return
        }

        if let currentUser = currentUser(in: calendarAccounts), let organizer = draft.organizer,
           organizer.email != currentUser.email.lowercased() {
            replaceOrganizer(with: Organizer(user: currentUser))
        }
    }

    private func replaceOrganizer(with newOrganizer: Organizer) {
        guard let previousOrganizer = draft.organizer else { return }

        let previousEmail = previousOrganizer.email.lowercased()
        let newEmail = newOrganizer.email.lowercased()

        guard previousEmail != newEmail else { return }

        draft.organizer = newOrganizer

        if !draft.attendees.contains(where: { $0.email.lowercased() == newEmail }),
           let organizerIndex = draft.attendees.firstIndex(where: { $0.email.lowercased() == previousEmail }) {
            draft.attendees[organizerIndex] = Attendee(organizer: newOrganizer)
        }
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
