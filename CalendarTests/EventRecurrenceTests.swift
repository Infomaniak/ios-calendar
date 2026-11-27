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
        let viewModel = EventFormViewModel(editionMode: .editDraft(draft: draft, editingEvent: .preview))

        #expect(viewModel.isRecurrenceEdited == false)

        viewModel.draft.recurrence = .none
        #expect(viewModel.isRecurrenceEdited)
        #expect(viewModel.isEdited)
    }

    @Test
    func weeklyOnStartWeekdayOmitsByDay() {
        let recurrence = CustomRecurrence(frequency: .weekly, interval: 3, weekdays: [.thursday])

        let rule = recurrence.sdkValue(startDate: thursdayStart, calendar: utcCalendar)

        #expect(rule == makeRule(frequency: .weekly, interval: 3))
    }

    @Test
    func endConditionsRoundTrip() {
        let count = CustomRecurrence(frequency: .daily, weekdays: [.thursday], end: .count(5))
        let until = CustomRecurrence(
            frequency: .daily,
            weekdays: [.thursday],
            end: .until(thursdayStart.addingTimeInterval(86400 * 10))
        )

        for recurrence in [count, until] {
            let rule = recurrence.sdkValue(startDate: thursdayStart, calendar: utcCalendar)
            let parsed = CustomRecurrence(rule: rule, startDate: thursdayStart, calendar: utcCalendar)
            #expect(parsed.end != .never)
        }
        #expect(count.sdkValue(startDate: thursdayStart, calendar: utcCalendar).occurrenceCount?.intValue == 5)
        #expect(until.sdkValue(startDate: thursdayStart, calendar: utcCalendar).until != nil)
    }

    @Test
    func weeklyOnSeveralWeekdaysUsesOrderedByDay() {
        let recurrence = CustomRecurrence(frequency: .weekly, weekdays: [.sunday, .monday, .thursday])

        let rule = recurrence.sdkValue(startDate: thursdayStart, calendar: utcCalendar)

        #expect(rule == makeRule(frequency: .weekly, byDay: [
            WeekDayNum(ordinal: nil, dayOfWeek: .monday),
            WeekDayNum(ordinal: nil, dayOfWeek: .thursday),
            WeekDayNum(ordinal: nil, dayOfWeek: .sunday)
        ]))
    }

    @Test
    func monthDayPatternsAnchorOnStartDate() {
        let dayOfMonth = CustomRecurrence(frequency: .monthly, weekdays: [.thursday], monthDayPattern: .dayOfMonth)
        let lastWeekday = CustomRecurrence(frequency: .monthly, weekdays: [.thursday], monthDayPattern: .lastWeekday)
        let firstWeekdayOfMonth = CustomRecurrence(frequency: .yearly, weekdays: [.thursday], monthDayPattern: .firstWeekday)

        #expect(dayOfMonth.sdkValue(startDate: thursdayStart, calendar: utcCalendar) == makeRule(frequency: .monthly))
        #expect(lastWeekday.sdkValue(startDate: thursdayStart, calendar: utcCalendar) == makeRule(
            frequency: .monthly,
            byDay: [WeekDayNum(ordinal: KotlinInt(int: -1), dayOfWeek: .thursday)]
        ))
        #expect(firstWeekdayOfMonth.sdkValue(startDate: thursdayStart, calendar: utcCalendar) == makeRule(
            frequency: .yearly,
            byDay: [WeekDayNum(ordinal: KotlinInt(int: 1), dayOfWeek: .thursday)],
            byMonth: [11]
        ))
    }

    @Test
    func ruleMapsToCustomRecurrence() {
        let weekly = makeRule(frequency: .weekly, interval: 2, byDay: [
            WeekDayNum(ordinal: nil, dayOfWeek: .monday),
            WeekDayNum(ordinal: nil, dayOfWeek: .friday)
        ])
        let monthly = makeRule(frequency: .monthly, byDay: [WeekDayNum(ordinal: KotlinInt(int: -1), dayOfWeek: .thursday)])

        #expect(CustomRecurrence(rule: weekly, startDate: thursdayStart, calendar: utcCalendar)
            == CustomRecurrence(frequency: .weekly, interval: 2, weekdays: [.monday, .friday]))
        #expect(CustomRecurrence(rule: monthly, startDate: thursdayStart, calendar: utcCalendar)
            == CustomRecurrence(frequency: .monthly, weekdays: [.thursday], monthDayPattern: .lastWeekday))
    }

    @Test
    func unchangedCustomRecurrencePreservesUnsupportedRule() throws {
        let originalRule = makeRule(frequency: .daily, interval: 2, occurrenceCount: 5)
        var draft = makeDraft(startDate: thursdayStart)
        draft.recurrence = .custom
        draft.customRecurrence = CustomRecurrence(rule: originalRule, startDate: thursdayStart, calendar: utcCalendar)

        let preserved = try draft.toEventEditData(preserving: makeEditData(rule: originalRule))
        draft.customRecurrence?.interval = 4
        let updated = try draft.toEventEditData(preserving: makeEditData(rule: originalRule))

        #expect(preserved.timing.recurrenceRule == originalRule)
        #expect(updated.timing.recurrenceRule == makeRule(frequency: .daily, interval: 4, occurrenceCount: 5))
    }

    @MainActor
    @Test
    func selectingCustomSeedsRecurrenceFromPreset() throws {
        let viewModel = EventFormViewModel(editionMode: .new(selectedDate: thursdayStart))
        viewModel.draft.startDate = thursdayStart
        viewModel.draft.startTimeZone = utcCalendar.timeZone
        viewModel.setRecurrence(.monthly)

        viewModel.setRecurrence(.custom)
        let rule = try #require(try viewModel.draft.sdkTiming().recurrenceRule)

        #expect(viewModel.draft.customRecurrence == CustomRecurrence(frequency: .monthly, weekdays: [.thursday]))
        #expect(rule == makeRule(frequency: .monthly))

        viewModel.setRecurrence(.none)
        #expect(viewModel.draft.customRecurrence == nil)
    }

    @MainActor
    @Test
    func implicitWeekdayFollowsStartDate() {
        let viewModel = EventFormViewModel(editionMode: .new(selectedDate: thursdayStart))
        viewModel.draft.startDate = thursdayStart
        viewModel.draft.startTimeZone = utcCalendar.timeZone
        viewModel.setRecurrence(.custom)

        viewModel.setDate(thursdayStart.addingTimeInterval(24 * 3600), for: .start)

        #expect(viewModel.draft.customRecurrence?.weekdays == [.friday])
    }

    /// Thursday 26 November 2026, 10:00 UTC.
    private let thursdayStart = Date(timeIntervalSince1970: 1_795_687_200)

    private var utcCalendar: Foundation.Calendar {
        var calendar = Foundation.Calendar(identifier: .gregorian)
        calendar.timeZone = Foundation.TimeZone(identifier: "UTC")!
        return calendar
    }

    private func makeDraft(startDate: Date) -> EventDraft {
        EventDraft(
            calendarId: "calendar-id",
            title: "Event title",
            startDate: startDate,
            startTimeZone: utcCalendar.timeZone,
            endDate: startDate.addingTimeInterval(3600),
            endTimeZone: utcCalendar.timeZone
        )
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
        byDay: [WeekDayNum] = [],
        byMonthDay: [Int32] = [],
        byMonth: [Int32] = []
    ) -> RecurrenceRule {
        RecurrenceRule(
            freq: frequency,
            interval: interval,
            occurrenceCount: occurrenceCount.map { KotlinInt(int: $0) },
            until: nil,
            byDay: byDay,
            byMonthDay: byMonthDay.map { KotlinInt(int: $0) },
            byMonth: byMonth.map { KotlinInt(int: $0) },
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
