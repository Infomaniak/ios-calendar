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
@testable import CalendarEventFormView
import Foundation
import Testing

@MainActor
struct EventFormViewModelTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func editingPrefillsStoredValuesWithoutMarkingFormChanged() throws {
        let original = try EventDraft(
            calendarId: "0",
            title: "Stored title",
            description: "Stored description",
            startDate: date("2026-09-22T10:10:00Z"),
            startTimeZone: timeZone("Europe/Zurich"),
            endDate: date("2026-09-22T11:10:00Z"),
            endTimeZone: timeZone("Europe/Zurich"),
            isOccupied: false
        )
        let editData = try original.toEventEditData()
        let draft = EventDraft.fromEvent(.preview, editData: editData)
        let viewModel = EventFormViewModel(editionMode: .editDraft(draft: draft))

        #expect(viewModel.draft.title == original.title)
        #expect(viewModel.draft.description == original.description)
        #expect(viewModel.draft.startDate == original.startDate)
        #expect(viewModel.draft.endDate == original.endDate)
        #expect(viewModel.draft.startTimeZone == original.startTimeZone)
        #expect(viewModel.draft.calendarId == original.calendarId)
        #expect(viewModel.draft.isOccupied == false)
        #expect(viewModel.isEdited == false)
    }

    @Test
    func editingWithoutEventCannotCreateAnotherEvent() async throws {
        let viewModel = try makeViewModel()

        await #expect(throws: EventOccurrenceError.self) {
            try await viewModel.saveEvent()
        }
    }

    @Test(arguments: [
        ("2026-09-22T09:10:00Z", "2026-09-22T11:10:00Z"),
        ("2026-09-22T10:40:00Z", "2026-09-22T11:10:00Z"),
        ("2026-09-22T11:10:00Z", "2026-09-22T11:10:00Z"),
        ("2026-09-22T12:10:00Z", "2026-09-22T13:10:00Z")
    ])
    func updatingStartDateShiftsEndOnlyWhenNecessary(start: String, expectedEnd: String) throws {
        let viewModel = try makeViewModel()
        let newStart = try date(start)

        viewModel.updateStartDate(newStart)

        #expect(viewModel.draft.startDate == newStart)
        #expect(try viewModel.draft.endDate == date(expectedEnd))
        #expect(viewModel.validationErrors.isEmpty)
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

        viewModel.updateTimeZone(newTimeZone, for: .start, calendar: calendar)

        #expect(try viewModel.draft.startDate == date(expectedStart))
        #expect(try viewModel.draft.endDate == date(expectedEnd))
        #expect(viewModel.draft.startTimeZone == newTimeZone)
        #expect(viewModel.draft.endTimeZone == newTimeZone)
        #expect(viewModel.validationErrors.isEmpty)
    }

    @Test(arguments: [
        ("2026-09-22T10:00:00Z", "2026-09-22T09:30:00Z"),
        ("2026-09-22T10:30:00Z", "2026-09-22T09:30:00Z"),
        ("2026-09-22T12:00:00Z", "2026-09-22T11:00:00Z")
    ])
    func endTimeZoneChangePreservesLocalTimeUnlessBeforeStart(end: String, expectedEnd: String) throws {
        let viewModel = try makeViewModel(
            start: "2026-09-22T09:30:00Z",
            end: end,
            startTimeZone: "Europe/Zurich",
            endTimeZone: "Europe/Zurich"
        )
        let originalStart = viewModel.draft.startDate
        let newTimeZone = try timeZone("Etc/GMT-3")

        viewModel.updateTimeZone(newTimeZone, for: .end, calendar: calendar)

        #expect(viewModel.draft.startDate == originalStart)
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

        viewModel.updateTimeZone(newTimeZone, for: .start, calendar: calendar)

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

        try viewModel.updateTimeZone(timeZone("Europe/Zurich"), for: .start, calendar: calendar)

        #expect(try viewModel.draft.startDate == date(expectedStart))
        #expect(try viewModel.draft.endDate == date(expectedEnd))
        #expect(viewModel.validationErrors.isEmpty)
    }

    @Test
    func changingSharedTimeZoneKeepsZeroDuration() throws {
        let viewModel = try makeViewModel(end: "2026-09-22T10:10:00Z")

        try viewModel.updateTimeZone(timeZone("America/New_York"), for: .start, calendar: calendar)

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

        try viewModel.updateTimeZone(timeZone("Etc/UTC"), for: pickerId, calendar: calendar)

        #expect(viewModel.draft == originalDraft)
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
        return EventFormViewModel(editionMode: .editDraft(draft: draft))
    }

    private func date(_ value: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: value))
    }

    private func timeZone(_ identifier: String) throws -> TimeZone {
        try #require(TimeZone(identifier: identifier))
    }
}
