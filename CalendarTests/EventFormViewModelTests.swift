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

@testable import CalendarCore
import CalendarCoreUI
@testable import CalendarEventFormView
import Foundation
import MultiplatformCalendar
import SwiftUI
import Testing

@MainActor
struct EventFormViewModelTests {
    private let calendar = Foundation.Calendar(identifier: .gregorian)

    @Test(arguments: [true, false])
    func newEventSelectsLastSavedWritableCalendarOrFallsBackToFirst(isSavedCalendarAvailable: Bool) throws {
        let suiteName = "EventFormViewModelTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        userDefaults.lastSelectedCalendarId = "saved"

        let viewModel = EventFormViewModel(editionMode: .new(selectedDate: Date()), userDefaults: userDefaults)
        let first = makeCalendar(id: "first")
        let saved = makeCalendar(id: "saved")
        viewModel.updateAvailableCalendars(isSavedCalendarAvailable ? [first, saved] : [first])

        #expect(viewModel.draft.calendarId == (isSavedCalendarAvailable ? saved.id : first.id))
        #expect(viewModel.isEdited == false)
        #expect(userDefaults.lastSelectedCalendarId == "saved")

        viewModel.draft.calendarId = first.id
        viewModel.updateAvailableCalendars([first, saved])
        #expect(viewModel.draft.calendarId == first.id)
    }

    @Test
    func editingEventKeepsItsCalendarRatherThanUsingLastSavedCalendar() throws {
        let suiteName = "EventFormViewModelTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        userDefaults.lastSelectedCalendarId = "saved"

        let draft = EventDraft(
            calendarId: "event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )
        let viewModel = EventFormViewModel(
            editionMode: .editDraft(draft: draft, editingEvent: .preview),
            userDefaults: userDefaults
        )
        viewModel.updateAvailableCalendars([makeCalendar(id: "saved")])

        #expect(viewModel.draft.calendarId == "event")
        #expect(viewModel.isEdited == false)
    }

    @Test
    func editingPrefillsStoredValuesWithoutMarkingFormChanged() throws {
        let original = try EventDraft(
            calendarId: "0",
            title: "Stored title",
            description: "Stored description\nwith multiple lines",
            startDate: date("2026-09-22T10:10:00Z"),
            startTimeZone: timeZone("Europe/Zurich"),
            endDate: date("2026-09-22T11:10:00Z"),
            endTimeZone: timeZone("Europe/Zurich"),
            isOccupied: false
        )
        let editData = try original.toEventEditData()
        let event = makeEvent(editData: editData)
        let draft = EventDraft(event: event, editData: editData)
        let viewModel = EventFormViewModel(editionMode: .editDraft(draft: draft, editingEvent: .preview), userDefaults: .shared)

        #expect(viewModel.draft.title == original.title)
        #expect(viewModel.draft.description == original.description)
        #expect(viewModel.draft.startDate == original.startDate)
        #expect(viewModel.draft.endDate == original.endDate)
        #expect(viewModel.draft.startTimeZone == original.startTimeZone)
        #expect(viewModel.draft.calendarId == original.calendarId)
        #expect(viewModel.draft.isOccupied == false)
        #expect(viewModel.isEdited == false)
    }

    @Test(arguments: [
        (EventFormViewModel.DatePickerId.start, "2026-09-22T09:10:00Z", "2026-09-22T09:10:00Z", "2026-09-22T11:10:00Z"),
        (.start, "2026-09-22T10:40:00Z", "2026-09-22T10:40:00Z", "2026-09-22T11:10:00Z"),
        (.start, "2026-09-22T11:10:00Z", "2026-09-22T11:10:00Z", "2026-09-22T11:10:00Z"),
        (.start, "2026-09-22T12:10:00Z", "2026-09-22T12:10:00Z", "2026-09-22T13:10:00Z"),
        (.end, "2026-09-22T09:10:00Z", "2026-09-22T08:10:00Z", "2026-09-22T09:10:00Z"),
        (.end, "2026-09-22T10:40:00Z", "2026-09-22T10:10:00Z", "2026-09-22T10:40:00Z"),
        (.end, "2026-09-22T10:10:00Z", "2026-09-22T10:10:00Z", "2026-09-22T10:10:00Z")
    ])
    func settingDateShiftsOtherBoundOnlyWhenNecessary(
        pickerId: EventFormViewModel.DatePickerId,
        newDate: String,
        expectedStart: String,
        expectedEnd: String
    ) throws {
        let viewModel = try makeViewModel()

        try viewModel.setDate(date(newDate), for: pickerId)

        #expect(try viewModel.draft.startDate == date(expectedStart))
        #expect(try viewModel.draft.endDate == date(expectedEnd))
        #expect(viewModel.validationErrors.isEmpty)
    }

    @Test(arguments: [EventFormViewModel.DatePickerId.start, .end])
    func settingDateOnInvalidDraftUsesZeroDuration(pickerId: EventFormViewModel.DatePickerId) throws {
        let viewModel = try makeViewModel(start: "2026-09-22T12:10:00Z", end: "2026-09-22T11:10:00Z")
        let newDate = try date(pickerId == .start ? "2026-09-22T13:10:00Z" : "2026-09-22T09:10:00Z")

        viewModel.setDate(newDate, for: pickerId)

        #expect(viewModel.draft.startDate == newDate)
        #expect(viewModel.draft.endDate == newDate)
    }

    @Test(arguments: [
        ("Europe/Zurich", "2026-09-22T08:10:00Z", "2026-09-22T09:10:00Z"),
        ("America/New_York", "2026-09-22T14:10:00Z", "2026-09-22T15:10:00Z"),
        ("Asia/Kathmandu", "2026-09-22T04:25:00Z", "2026-09-22T05:25:00Z"),
        ("Pacific/Kiritimati", "2026-09-21T20:10:00Z", "2026-09-21T21:10:00Z")
    ])
    func startTimeZoneChangePreservesBothLocalTimes(
        identifier: String,
        expectedStart: String,
        expectedEnd: String
    ) throws {
        let viewModel = try makeViewModel()
        let newTimeZone = try timeZone(identifier)

        viewModel.setTimeZone(newTimeZone, for: .start, calendar: calendar)

        #expect(try viewModel.draft.startDate == date(expectedStart))
        #expect(try viewModel.draft.endDate == date(expectedEnd))
        #expect(viewModel.draft.startTimeZone == newTimeZone)
        #expect(viewModel.draft.endTimeZone == newTimeZone)
        #expect(viewModel.validationErrors.isEmpty)
    }

    @Test(arguments: [
        ("2026-09-22T10:00:00Z", "2026-09-22T08:30:00Z", "2026-09-22T09:00:00Z"),
        ("2026-09-22T10:30:00Z", "2026-09-22T09:30:00Z", "2026-09-22T09:30:00Z"),
        ("2026-09-22T12:00:00Z", "2026-09-22T09:30:00Z", "2026-09-22T11:00:00Z")
    ])
    func endTimeZoneChangePreservesLocalTimeAndKeepsIntervalValid(
        end: String,
        expectedStart: String,
        expectedEnd: String
    ) throws {
        let viewModel = try makeViewModel(
            start: "2026-09-22T09:30:00Z",
            end: end,
            startTimeZone: "Europe/Zurich",
            endTimeZone: "Europe/Zurich"
        )
        let newTimeZone = try timeZone("Etc/GMT-3")

        viewModel.setTimeZone(newTimeZone, for: .end, calendar: calendar)

        #expect(try viewModel.draft.startDate == date(expectedStart))
        #expect(try viewModel.draft.startTimeZone == timeZone("Europe/Zurich"))
        #expect(try viewModel.draft.endDate == date(expectedEnd))
        #expect(viewModel.draft.endTimeZone == newTimeZone)
        #expect(viewModel.validationErrors.isEmpty)
    }

    @Test(arguments: [
        ("Etc/GMT-3", "2026-09-22T07:10:00Z", "2026-09-22T11:10:00Z"),
        ("America/New_York", "2026-09-22T14:10:00Z", "2026-09-22T15:10:00Z")
    ])
    func startTimeZoneChangeKeepsIndependentEndTimeZone(
        identifier: String,
        expectedStart: String,
        expectedEnd: String
    ) throws {
        let viewModel = try makeViewModel(endTimeZone: "Europe/Zurich")
        let newTimeZone = try timeZone(identifier)

        viewModel.setTimeZone(newTimeZone, for: .start, calendar: calendar)

        #expect(try viewModel.draft.startDate == date(expectedStart))
        #expect(viewModel.draft.startTimeZone == newTimeZone)
        #expect(try viewModel.draft.endDate == date(expectedEnd))
        #expect(try viewModel.draft.endTimeZone == timeZone("Europe/Zurich"))
        #expect(viewModel.validationErrors.isEmpty)
    }

    @Test(arguments: [
        ("2026-01-22T10:10:00Z", "2026-01-22T11:10:00Z", "2026-01-22T09:10:00Z", "2026-01-22T10:10:00Z"),
        ("2026-07-22T10:10:00Z", "2026-07-22T11:10:00Z", "2026-07-22T08:10:00Z", "2026-07-22T09:10:00Z"),
        ("2026-03-29T01:30:00Z", "2026-03-29T03:30:00Z", "2026-03-29T00:30:00Z", "2026-03-29T01:30:00Z")
    ])
    func timeZoneChangeUsesDaylightSavingOffsetAtEachDate(
        start: String,
        end: String,
        expectedStart: String,
        expectedEnd: String
    ) throws {
        let viewModel = try makeViewModel(start: start, end: end)

        try viewModel.setTimeZone(timeZone("Europe/Zurich"), for: .start, calendar: calendar)

        #expect(try viewModel.draft.startDate == date(expectedStart))
        #expect(try viewModel.draft.endDate == date(expectedEnd))
        #expect(viewModel.validationErrors.isEmpty)
    }

    @Test
    func changingSharedTimeZoneKeepsZeroDuration() throws {
        let viewModel = try makeViewModel(end: "2026-09-22T10:10:00Z")

        try viewModel.setTimeZone(timeZone("America/New_York"), for: .start, calendar: calendar)

        #expect(try viewModel.draft.startDate == date("2026-09-22T14:10:00Z"))
        #expect(viewModel.draft.endDate == viewModel.draft.startDate)
        #expect(viewModel.validationErrors.isEmpty)
    }

    @Test(arguments: [EventFormViewModel.DatePickerId.start, .end])
    func selectingSameTimeZoneLeavesDraftUnchanged(pickerId: EventFormViewModel.DatePickerId) throws {
        let viewModel = try makeViewModel()
        viewModel.draft.startDate += 0.125
        viewModel.draft.endDate += 0.125
        let originalDraft = viewModel.draft

        try viewModel.setTimeZone(timeZone("Etc/UTC"), for: pickerId, calendar: calendar)

        #expect(viewModel.draft == originalDraft)
    }

    @Test
    func editingAlarmsMarksFormChanged() throws {
        let viewModel = try makeViewModel()

        viewModel.draft.alarms.append(EventAlarmDraft(offset: .oneHourBefore))

        #expect(viewModel.isEdited)
    }

    @Test
    func addingThenRemovingAlarmRestoresUnchangedForm() throws {
        let viewModel = try makeViewModel()
        let originalDraft = viewModel.draft
        let alarm = EventAlarmDraft(action: .email, offset: .oneHourBefore)

        viewModel.draft.alarms.append(alarm)
        #expect(viewModel.isEdited)

        viewModel.draft.alarms.removeAll { $0.id == alarm.id }

        #expect(viewModel.draft == originalDraft)
        #expect(!viewModel.isEdited)
    }

    @Test
    func emptyAlarmRowAddsAlarmsAndStaysEmpty() throws {
        let viewModel = try makeViewModel()
        let rows = makeAlarmRows(viewModel: viewModel)
        let binding = rows.newAlarmBinding
        let first = EventAlarmDraft(action: .email, offset: .oneHourBefore)
        let second = EventAlarmDraft(action: .email, offset: .fiveMinutesBefore)

        #expect(binding.wrappedValue == nil)
        binding.wrappedValue = nil
        #expect(viewModel.draft.alarms.isEmpty)
        #expect(!viewModel.isEdited)

        binding.wrappedValue = first
        #expect(binding.wrappedValue == nil)
        binding.wrappedValue = second
        binding.wrappedValue = nil

        #expect(viewModel.draft.alarms == [first, second])
        #expect(binding.wrappedValue == nil)
    }

    @Test
    func settingAlarmToNoneRemovesOnlyThatRow() throws {
        let viewModel = try makeViewModel()
        let first = EventAlarmDraft(action: .email, offset: .oneDayBefore)
        let middle = EventAlarmDraft(action: .email, offset: .oneHourBefore)
        let last = EventAlarmDraft(action: .email, offset: .fiveMinutesBefore)
        let notification = EventAlarmDraft(offset: .atTimeOfEvent)
        viewModel.draft.alarms = [notification, first, middle, last]
        let rows = makeAlarmRows(viewModel: viewModel)

        let middleBinding = rows.alarmBinding(for: middle)
        middleBinding.wrappedValue = nil
        #expect(viewModel.draft.alarms.map(\.id) == [notification.id, first.id, last.id])
        #expect(middleBinding.wrappedValue == nil)

        rows.alarmBinding(for: first).wrappedValue = nil
        #expect(viewModel.draft.alarms.map(\.id) == [notification.id, last.id])

        rows.alarmBinding(for: last).wrappedValue = nil
        #expect(viewModel.draft.alarms == [notification])

        let editData = try viewModel.draft.toEventEditData()
        let alarms = try #require(editData.alarms as? AlarmListEditReplace)
        #expect(alarms.alarms.count == 1)
        #expect(UIAlarmTrigger(alarmTrigger: alarms.alarms[0].trigger) == notification.trigger)
    }

    @Test
    func alarmBindingsFollowIdentityAfterOtherRowsAreRemoved() throws {
        let viewModel = try makeViewModel()
        let first = EventAlarmDraft(action: .email, offset: .oneHourBefore)
        let second = EventAlarmDraft(action: .email, offset: .fiveMinutesBefore)
        viewModel.draft.alarms = [first, second]
        let rows = makeAlarmRows(viewModel: viewModel)
        let firstBinding = rows.alarmBinding(for: first)
        let secondBinding = rows.alarmBinding(for: second)

        firstBinding.wrappedValue = nil
        secondBinding.wrappedValue = second.newWith(offset: .oneDayBefore)

        #expect(viewModel.draft.alarms == [second.newWith(offset: .oneDayBefore)])
        firstBinding.wrappedValue = first.newWith(offset: .oneHourBefore)
        #expect(viewModel.draft.alarms == [second.newWith(offset: .oneDayBefore)])
    }

    @Test
    func changingAlarmTypeUpdatesSameAlarmWithoutDuplicatingIt() throws {
        let viewModel = try makeViewModel()
        let alarm = EventAlarmDraft(action: .email, offset: .oneHourBefore)
        viewModel.draft.alarms = [alarm]
        let rows = makeAlarmRows(viewModel: viewModel)
        let updated = EventAlarmDraft(id: alarm.id, action: .display, trigger: .relative(offset: -600, relatedTo: .start))

        rows.alarmBinding(for: alarm).wrappedValue = updated

        #expect(viewModel.draft.alarms == [updated])
        #expect(viewModel.draft.alarms[0].id == alarm.id)
    }

    @Test
    func prefilledAlarmsDoNotMarkFormChanged() throws {
        let original = try EventDraft(
            calendarId: "0",
            startDate: date("2026-09-22T10:10:00Z"),
            startTimeZone: timeZone("Europe/Zurich"),
            endDate: date("2026-09-22T11:10:00Z"),
            endTimeZone: timeZone("Europe/Zurich")
        )
        let editData = try original.toEventEditData()
        let event = makeEvent(editData: editData, alarms: [
            EventAlarm(
                action: AlarmActionEmail(),
                trigger: AlarmTriggerRelative(offset: KotlinDuration.rawValue(fromTimeInterval: -3600), relatedTo: .start),
                id: nil
            ),
            EventAlarm(
                action: AlarmActionDisplay(),
                trigger: AlarmTriggerRelative(offset: KotlinDuration.rawValue(fromTimeInterval: -300), relatedTo: .start),
                id: nil
            )
        ])
        let draft = EventDraft(event: event, editData: editData)
        let viewModel = EventFormViewModel(
            editionMode: .editDraft(draft: draft, editingEvent: UIEventDetails(event: event, userEmail: nil)),
            userDefaults: .shared
        )

        #expect(viewModel.draft.alarms.count == 2)
        #expect(viewModel.draft.alarms.map(\.action) == [.email, .display])
        #expect(viewModel.draft.alarms.map(\.trigger) == [
            AlarmOffset.oneHourBefore.trigger,
            .relative(offset: -300, relatedTo: .start)
        ])
        #expect(viewModel.isEdited == false)
    }

    private func makeEvent(editData: EventEditData, alarms: [EventAlarm] = []) -> MultiplatformCalendar.Event {
        let themedColor = ThemedColor(light: 0, dark: 0)
        return MultiplatformCalendar.Event(
            masterEventId: "event",
            occurrenceId: OccurrenceId.Master(masterId: "event"),
            calendarId: editData.calendarId,
            accountId: 1,
            title: editData.title,
            description: editData.description_,
            location: editData.location,
            status: .confirmed,
            timeBlocking: editData.timeBlocking,
            classification: ClassificationPublic(),
            categories: [],
            meetRoomUrl: nil,
            bookableUuid: nil,
            attachments: [],
            timing: editData.timing,
            lastModified: nil,
            attendees: [],
            organizer: nil,
            colors: EventColors(
                calendarSourceColor: 0,
                sourceColor: 0,
                containerColor: 0,
                onContainerColor: themedColor,
                containerVariantColor: 0,
                onContainerVariantColor: themedColor
            ),
            canEdit: true,
            alarms: alarms,
            recurrenceMasterBounds: nil
        )
    }

    private func makeAlarmRows(viewModel: EventFormViewModel) -> EventAlarmTypeRowsView {
        EventAlarmTypeRowsView(
            alarms: Binding(get: { viewModel.draft.alarms }, set: { viewModel.draft.alarms = $0 }),
            action: .email
        )
    }

    private func makeViewModel(
        start: String = "2026-09-22T10:10:00Z",
        end: String = "2026-09-22T11:10:00Z",
        startTimeZone: String = "Etc/UTC",
        endTimeZone: String = "Etc/UTC"
    ) throws -> EventFormViewModel {
        let draft = try EventDraft(
            calendarId: "calendar-id",
            startDate: date(start),
            startTimeZone: timeZone(startTimeZone),
            endDate: date(end),
            endTimeZone: timeZone(endTimeZone)
        )
        return EventFormViewModel(editionMode: .editDraft(draft: draft, editingEvent: .preview), userDefaults: .shared)
    }

    private func makeCalendar(id: String) -> UICalendar {
        UICalendar(
            id: id,
            displayName: id,
            colorArgb: 0,
            accountId: 1,
            isVisible: true,
            accessLevel: .owner
        )
    }

    private func date(_ value: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: value))
    }

    private func timeZone(_ identifier: String) throws -> Foundation.TimeZone {
        let timeZone = Foundation.TimeZone(identifier: identifier)
        return try #require(timeZone)
    }
}
