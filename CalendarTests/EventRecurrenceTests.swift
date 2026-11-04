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
import Testing

struct EventRecurrenceTests {
    @Test
    func missingRuleMapsToNone() {
        #expect(EventRecurrence(rule: nil) == .none)
    }

    @Test(arguments: EventRecurrence.presets)
    func simpleRuleMapsToPreset(recurrence: EventRecurrence) throws {
        let frequency = try #require(frequency(for: recurrence))

        #expect(EventRecurrence(rule: makeRule(frequency: frequency)) == recurrence)
    }

    @Test
    func complexRulesMapToCustom() {
        #expect(EventRecurrence(rule: makeRule(frequency: .weekly, interval: 2)) == .custom)
        #expect(EventRecurrence(rule: makeRule(frequency: .daily, occurrenceCount: 5)) == .custom)
        #expect(EventRecurrence(rule: makeRule(frequency: .monthly, byMonthDay: [15])) == .custom)
        #expect(EventRecurrence(rule: makeRule(frequency: .hourly)) == .custom)
    }

    @Test
    func recurrenceDatesWithoutRuleMapToCustom() {
        let timing = EventTiming(
            bounds: makeBounds(),
            recurrenceRule: nil,
            rDates: [makeRecurrenceDate()],
            exDates: []
        )

        #expect(EventRecurrence(timing: timing) == .custom)
    }

    @Test(arguments: EventRecurrence.presets)
    func presetCreatesSimpleRule(recurrence: EventRecurrence) throws {
        let frequency = try #require(frequency(for: recurrence))
        var draft = makeDraft()
        draft.recurrence = recurrence

        let rule = try #require(try draft.toEventEditData().timing.recurrenceRule)

        #expect(rule == makeRule(frequency: frequency))
    }

    @Test
    func customPreservesOriginalRule() throws {
        let originalRule = makeRule(frequency: .weekly, interval: 2)
        var draft = makeDraft()
        draft.recurrence = .custom

        let updated = try draft.toEventEditData(preserving: makeEditData(rule: originalRule))

        #expect(updated.timing.recurrenceRule == originalRule)
    }

    @Test
    func changingPresetReplacesComplexRule() throws {
        var draft = makeDraft()
        draft.recurrence = .monthly

        let updated = try draft.toEventEditData(preserving: makeEditData(rule: makeRule(frequency: .weekly, interval: 2)))

        #expect(updated.timing.recurrenceRule == makeRule(frequency: .monthly))
    }

    @Test
    func noneClearsRuleAndRecurrenceDates() throws {
        let original = makeEditData(rule: makeRule(frequency: .daily), rDates: [makeRecurrenceDate()])
        var draft = makeDraft()
        draft.recurrence = .none

        let updated = try draft.toEventEditData(preserving: original)

        #expect(updated.timing.recurrenceRule == nil)
        #expect(updated.timing.rDates.isEmpty)
        #expect(updated.timing.exDates.isEmpty)
    }

    @Test
    func keepingPresetPreservesRecurrenceDates() throws {
        let original = makeEditData(rule: makeRule(frequency: .daily), rDates: [makeRecurrenceDate()])
        var draft = makeDraft()
        draft.recurrence = .daily

        let updated = try draft.toEventEditData(preserving: original)

        #expect(updated.timing.recurrenceRule == makeRule(frequency: .daily))
        #expect(updated.timing.rDates.count == 1)
        #expect(updated.timing.exDates.count == 1)
    }

    @MainActor
    @Test
    func viewModelTracksRecurrenceEdition() {
        var draft = makeDraft()
        draft.recurrence = .weekly
        let viewModel = EventFormViewModel(
            editionMode: .editDraft(draft: draft, editingEvent: .preview),
            userDefaults: .shared
        )

        #expect(viewModel.isRecurrenceEdited == false)

        viewModel.draft.recurrence = .none
        #expect(viewModel.isRecurrenceEdited)
        #expect(viewModel.isEdited)
    }

    private func frequency(for recurrence: EventRecurrence) -> Frequency? {
        switch recurrence {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        case .none, .custom: nil
        }
    }

    private func makeDraft() -> EventDraft {
        let startDate = Date(timeIntervalSince1970: 1000)
        return EventDraft(
            calendarId: "calendar-id",
            title: "Event title",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(3600)
        )
    }

    private func makeBounds() -> EventBoundsFloating {
        EventBoundsFloating(
            start: LocalDateTime(year: 2027, month: 1, day: 1, hour: 10, minute: 0, second: 0, nanosecond: 0),
            end: LocalDateTime(year: 2027, month: 1, day: 1, hour: 11, minute: 0, second: 0, nanosecond: 0)
        )
    }

    private func makeRecurrenceDate() -> IcalDateValueFloating {
        IcalDateValueFloating(
            localDateTime: LocalDateTime(year: 2027, month: 1, day: 15, hour: 10, minute: 0, second: 0, nanosecond: 0)
        )
    }

    private func makeEditData(rule: RecurrenceRule?, rDates: [IcalDateValueFloating] = []) -> EventEditData {
        EventEditData(
            title: "Event title",
            timing: EventTiming(bounds: makeBounds(), recurrenceRule: rule, rDates: rDates, exDates: rDates),
            location: nil,
            description: nil,
            timeBlocking: nil,
            calendarId: "calendar-id",
            eventColor: nil,
            alarms: AlarmListEditReplace(alarms: []),
            attendees: [],
            organizer: nil,
            meetRoom: nil
        )
    }

    private func makeRule(
        frequency: Frequency,
        interval: Int32 = 1,
        occurrenceCount: Int32? = nil,
        byMonthDay: [Int32] = []
    ) -> RecurrenceRule {
        RecurrenceRule(
            freq: frequency,
            interval: interval,
            occurrenceCount: occurrenceCount.map { KotlinInt(int: $0) },
            until: nil,
            byDay: [],
            byMonthDay: byMonthDay.map { KotlinInt(int: $0) },
            byMonth: [],
            byOccurrencePosition: [],
            weekStart: nil,
            byHour: [],
            byMinute: [],
            bySecond: [],
            byYearDay: [],
            byWeekNumber: []
        )
    }
}
