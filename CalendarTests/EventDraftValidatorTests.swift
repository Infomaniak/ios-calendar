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
import Foundation
import MultiplatformCalendar
import Testing

struct EventDraftValidatorTests {
    private let validator = EventDraftValidator()

    @Test
    func validDraftHasNoErrors() {
        let draft = makeDraft()

        #expect(validator.validate(draft).isEmpty)
    }

    @Test
    func valuesAtMaximumLimitsAreValid() {
        var draft = makeDraft()
        draft.title = String(repeating: "a", count: EventDraftValidator.maximumTitleCharacterCount)
        draft.description = String(repeating: "a", count: EventDraftValidator.maximumDescriptionCharacterCount)
        draft.attendees = makeAttendees(count: EventDraftValidator.maximumAttendeeCount)
        draft.endDate = draft.startDate

        #expect(validator.validate(draft).isEmpty)
    }

    @Test
    func titleOverMaximumLimitIsInvalid() {
        var draft = makeDraft()
        draft.title = String(repeating: "a", count: EventDraftValidator.maximumTitleCharacterCount + 1)

        #expect(validator.validate(draft) == [.titleTooLong])
    }

    @Test
    func descriptionOverMaximumLimitIsInvalid() {
        var draft = makeDraft()
        draft.description = String(repeating: "a", count: EventDraftValidator.maximumDescriptionCharacterCount + 1)

        #expect(validator.validate(draft) == [.descriptionTooLong])
    }

    @Test
    func attendeeCountOverMaximumLimitIsInvalid() {
        var draft = makeDraft()
        draft.attendees = makeAttendees(count: EventDraftValidator.maximumAttendeeCount + 1)

        #expect(validator.validate(draft) == [.tooManyAttendees])
    }

    @Test
    func nilCalendarIsInvalid() {
        var draft = makeDraft()
        draft.calendarId = nil

        #expect(validator.validate(draft) == [.missingCalendar])
    }

    @Test
    func emptyCalendarIsInvalid() {
        var draft = makeDraft()
        draft.calendarId = ""

        #expect(validator.validate(draft) == [.missingCalendar])
    }

    @Test
    func endDateBeforeStartDateIsInvalid() {
        var draft = makeDraft()
        draft.endDate = draft.startDate.addingTimeInterval(-1)

        #expect(validator.validate(draft) == [.invalidDates])
    }

    @Test
    func validateReturnsAllErrors() {
        let date = Date(timeIntervalSince1970: 1000)
        let draft = EventDraft(
            title: String(repeating: "a", count: EventDraftValidator.maximumTitleCharacterCount + 1),
            description: String(repeating: "a", count: EventDraftValidator.maximumDescriptionCharacterCount + 1),
            startDate: date,
            endDate: date.addingTimeInterval(-1),
            attendees: makeAttendees(count: EventDraftValidator.maximumAttendeeCount + 1)
        )

        #expect(validator.validate(draft) == Set(EventDraftValidator.ValidationError.allCases))
    }

    @Test
    func validationErrorsDescriptionFollowsCaseOrder() {
        let errors: Set<EventDraftValidator.ValidationError> = [.missingCalendar, .titleTooLong, .invalidDates]
        let validationErrors = EventDraftValidator.ValidationErrors(errors: errors)
        let expectedDescription = [
            EventDraftValidator.ValidationError.titleTooLong.errorDescription,
            EventDraftValidator.ValidationError.missingCalendar.errorDescription,
            EventDraftValidator.ValidationError.invalidDates.errorDescription
        ].joined(separator: "\n")

        #expect(validationErrors.errorDescription == expectedDescription)
    }

    @Test
    func updateRejectsInvalidDraftBeforeResolvingOccurrence() async throws {
        var draft = makeDraft()
        draft.calendarId = nil

        await #expect(throws: EventDraftValidator.ValidationErrors.self) {
            try await UpdateEventUseCase().execute(
                occurrenceId: "missing-event",
                scope: .thisOccurrence,
                draft: draft
            )
        }
    }

    @Test
    func updatingDraftPreservesUneditedEventFields() throws {
        let original = try makeDraft().toEventEditData()
        let attendee = AttendeeEdit(email: "guest@example.com", displayName: "Guest", type: .individual, role: .requested)
        let organizer = Organizer(email: "organizer@example.com", displayName: "Organizer", contact: nil)
        let recurrenceDate = IcalDateValueFloating(
            localDateTime: LocalDateTime(year: 2027, month: 1, day: 15, hour: 10, minute: 0, second: 0, nanosecond: 0)
        )
        let timing = EventTiming(
            bounds: original.timing.bounds,
            recurrenceRule: original.timing.recurrenceRule,
            rDates: [recurrenceDate],
            exDates: [recurrenceDate]
        )
        let stored = try EventEditData(
            title: original.title,
            timing: timing,
            location: "Meeting room",
            description: original.description_,
            timeBlocking: nil,
            calendarId: original.calendarId,
            eventColor: original.eventColor,
            alarms: original.alarms,
            attendees: [attendee],
            organizer: organizer
        )
        var draft = makeDraft()
        draft.title = "Updated title"
        let updated = try draft.toEventEditData(preserving: stored)

        #expect(updated.title == "Updated title")
        #expect(updated.location == stored.location)
        #expect(updated.timeBlocking == nil)
        #expect(updated.alarms === stored.alarms)
        #expect(updated.attendees == stored.attendees)
        #expect(updated.organizer == stored.organizer)
        #expect(updated.timing.rDates.first as? IcalDateValueFloating == recurrenceDate)
        #expect(updated.timing.exDates.first as? IcalDateValueFloating == recurrenceDate)
    }

    @Test
    func allDayDraftUsesAllDayBounds() throws {
        var draft = makeDraft()
        draft.allDay = true
        draft.endDate = draft.startDate.addingTimeInterval(86400)
        let timing = try draft.toEventEditData().timing
        let bounds = try #require(timing.bounds as? EventBoundsAllDay)

        #expect(timing.isAllDay)
        #expect(bounds.start != bounds.end)
    }

    @Test
    func floatingDraftUsesFloatingBounds() throws {
        var draft = makeDraft()
        draft.startTimeZone = nil
        draft.endTimeZone = nil
        let timing = try draft.toEventEditData().timing

        #expect(timing.bounds is EventBoundsFloating)
        #expect(!timing.isAllDay)
        #expect(timing.startInstantLocal().toNSDate() == draft.startDate)
        #expect(timing.endInstantLocal().toNSDate() == draft.endDate)
    }

    @Test
    func zonedDraftPreservesBothTimeZonesAndInstants() throws {
        var draft = makeDraft()
        draft.startTimeZone = Foundation.TimeZone(identifier: "Europe/Zurich")
        draft.endTimeZone = Foundation.TimeZone(identifier: "Europe/London")
        let timing = try draft.toEventEditData().timing
        let bounds = try #require(timing.bounds as? EventBoundsZoned)

        #expect(bounds.start.timeZone.id == "Europe/Zurich")
        #expect(bounds.end.timeZone.id == "Europe/London")
        #expect(timing.startInstantLocal().toNSDate() == draft.startDate)
        #expect(timing.endInstantLocal().toNSDate() == draft.endDate)
    }

    private func makeDraft() -> EventDraft {
        let startDate = Date(timeIntervalSince1970: 1000)
        return EventDraft(
            calendarId: "calendar-id",
            title: "Event title",
            description: "Event description",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(3600)
        )
    }

    private func makeAttendees(count: Int) -> [Attendee] {
        return (0 ..< count).map {
            Attendee(
                email: "attendee\($0)@example.com",
                displayName: nil,
                status: .needsAction,
                role: .requested,
                isOrganizer: false,
                responseNeeded: true
            )
        }
    }
}
