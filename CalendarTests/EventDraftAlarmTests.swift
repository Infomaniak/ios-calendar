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
import Foundation
import MultiplatformCalendar
import Testing

struct EventDraftAlarmTests {
    @Test
    func newDraftStartsWithEmailAndNotificationDisabled() throws {
        var draft = EventDraft.empty()
        draft.calendarId = "calendar-id"

        #expect(draft.alarms.map(\.action) == [.email, .display])
        #expect(draft.alarms.allSatisfy { $0.trigger == nil })

        let editData = try draft.toEventEditData()
        let alarms = try #require((editData.alarms as? AlarmListEditReplace)?.alarms)
        #expect(alarms.isEmpty)
    }

    @Test
    func draftWithoutAlarmsStartsWithDisabledRowsAndPreservesOriginalData() throws {
        let draft = try makeDraft()
        let storedEditData = try makeStoredEditData(alarms: [])

        #expect(draft.alarms.map(\.action) == [.email, .display])
        #expect(draft.alarms.allSatisfy { $0.trigger == nil })
        #expect(try draft.toEventEditData(preserving: storedEditData).alarms is AlarmListEditPreserve)
    }

    @Test
    func enablingDefaultEmailAlarmReplacesEmptyAlarms() throws {
        var draft = try makeDraft()
        let storedEditData = try makeStoredEditData(alarms: [])
        draft.alarms[0] = draft.alarms[0].with(offset: .fiveMinutesBefore)

        let editData = try draft.toEventEditData(preserving: storedEditData)
        let alarms = try #require((editData.alarms as? AlarmListEditReplace)?.alarms)

        #expect(alarms.count == 1)
        #expect(try UIEventAlarm(sdk: #require(alarms.first)).action == .email)
    }

    @Test
    func fromEventPrefillsAlarms() throws {
        let editData = try makeDraft().toEventEditData()

        let draft = EventDraft.fromEvent(.alarmsPreview, editData: editData)

        #expect(draft.alarms.count == 2)
        #expect(draft.alarms[0].trigger == .relative(offset: -300, relatedTo: .start))
        #expect(draft.alarms[1].trigger == .relative(offset: -3600, relatedTo: .end))
    }

    @Test
    func creatingEventReplacesAlarms() throws {
        var draft = try makeDraft()
        draft.alarms = [
            UIEventAlarm(offset: .atTimeOfEvent),
            UIEventAlarm(offset: .oneDayBefore)
        ]

        let editData = try draft.toEventEditData()
        let alarms = try #require((editData.alarms as? AlarmListEditReplace)?.alarms)

        #expect(alarms.count == 2)

        let firstTrigger = try #require(alarms[0].trigger as? AlarmTriggerRelative)
        #expect(firstTrigger.offset == 0)
        #expect(firstTrigger.relatedTo == TriggerRelation.start)

        let secondTrigger = try #require(alarms[1].trigger as? AlarmTriggerRelative)
        #expect(secondTrigger.offset == -86400)
        #expect(secondTrigger.relatedTo == TriggerRelation.start)
    }

    @Test
    func unchangedAlarmsPreserveOriginalEditData() throws {
        let storedEditData = try makeStoredEditData(alarms: [UIEventAlarm(offset: .oneHourBefore)])
        let draft = try makeDraft(alarms: [UIEventAlarm(offset: .oneHourBefore)])

        let editData = try draft.toEventEditData(preserving: storedEditData)

        #expect(editData.alarms is AlarmListEditPreserve)
    }

    @Test
    func editedAlarmsAreReplaced() throws {
        let storedEditData = try makeStoredEditData(alarms: [UIEventAlarm(offset: .oneHourBefore)])
        var draft = try makeDraft(alarms: [UIEventAlarm(offset: .oneHourBefore)])
        draft.alarms.removeLast()
        draft.alarms.append(UIEventAlarm(offset: .fiveMinutesBefore))

        let editData = try draft.toEventEditData(preserving: storedEditData)
        let alarms = try #require((editData.alarms as? AlarmListEditReplace)?.alarms)

        #expect(alarms.count == 1)
        let trigger = try #require(alarms[0].trigger as? AlarmTriggerRelative)
        #expect(trigger.offset == -300)
    }

    @Test
    func withOffsetRebuildsTriggerAndPreservesOtherFields() {
        let alarm = UIEventAlarm(
            action: .email,
            trigger: .relative(offset: -300, relatedTo: .start),
            attachments: ["attachment"],
            attendees: ["attendee@example.com"],
            description: "description",
            summary: "summary"
        )

        let updated = alarm.with(offset: .oneDayBefore)

        #expect(updated.trigger == .relative(offset: -86400, relatedTo: .start))
        #expect(updated.offset == .oneDayBefore)
        #expect(updated.action == .email)
        #expect(updated.attachments == ["attachment"])
        #expect(updated.attendees == ["attendee@example.com"])
        #expect(updated.description == "description")
        #expect(updated.summary == "summary")
        #expect(alarm.trigger == .relative(offset: -300, relatedTo: .start))
    }

    @Test
    func selectingNoneClearsAlarmTrigger() {
        let alarm = UIEventAlarm(offset: .fiveMinutesBefore)

        let updated = alarm.with(offset: .none)

        #expect(updated.action == .display)
        #expect(updated.trigger == nil)
        #expect(updated.offset == .none)
    }

    @Test(arguments: AlarmOffset.presets.filter { $0 != .none })
    func presetRoundTripsThroughSDK(offset: AlarmOffset) throws {
        let alarm = UIEventAlarm(offset: offset)

        let sdkAlarm = try #require(alarm.toSDK())
        let roundTripped = UIEventAlarm(sdk: sdkAlarm)

        #expect(roundTripped.trigger == offset.trigger)
        #expect(roundTripped.offset == offset)
    }

    @Test
    func onlyEmailAndNotificationAlarmsAreEditable() {
        #expect(UIAlarmAction.email.isEditable)
        #expect(UIAlarmAction.display.isEditable)
        #expect(!UIAlarmAction.audio.isEditable)
        #expect(!UIAlarmAction.unknown("X-CUSTOM").isEditable)
    }

    // MARK: - Helpers

    private func makeDraft(alarms: [UIEventAlarm] = []) throws -> EventDraft {
        try EventDraft(
            calendarId: "calendar-id",
            startDate: date("2026-09-22T10:10:00Z"),
            endDate: date("2026-09-22T11:10:00Z"),
            alarms: alarms
        )
    }

    /// Simulates the SDK handing back stored alarms untouched when re-editing an event.
    private func makeStoredEditData(alarms: [UIEventAlarm]) throws -> EventEditData {
        let editData = try makeDraft(alarms: alarms).toEventEditData()
        return editData.doCopy(
            title: editData.title,
            timing: editData.timing,
            location: editData.location,
            description: editData.description_,
            timeBlocking: editData.timeBlocking,
            calendarId: editData.calendarId,
            eventColor: editData.eventColor,
            alarms: AlarmListEditPreserve()
        )
    }

    private func date(_ value: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: value))
    }
}
