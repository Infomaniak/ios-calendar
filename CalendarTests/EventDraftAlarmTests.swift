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
import CalendarResources
import Foundation
import MultiplatformCalendar
import Testing

struct EventDraftAlarmTests {
    @Test
    func unsupportedAlarmActionsUseLocalizedOtherLabel() {
        #expect(UIAlarmAction.audio.label == CalendarResourcesStrings.notificationTypeOther)
        #expect(UIAlarmAction.unknown("X-CUSTOM").label == CalendarResourcesStrings.notificationTypeOther)
    }

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
        #expect(try EventAlarmDraft(sdk: #require(alarms.first)).action == .email)
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
            EventAlarmDraft(offset: .atTimeOfEvent),
            EventAlarmDraft(offset: .oneDayBefore)
        ]

        let editData = try draft.toEventEditData()
        let alarms = try #require((editData.alarms as? AlarmListEditReplace)?.alarms)

        #expect(alarms.count == 2)

        let firstTrigger = try #require(alarms[0].trigger as? AlarmTriggerRelative)
        #expect(firstTrigger.offset == 0)
        #expect(firstTrigger.relatedTo == TriggerRelation.start)

        let secondTrigger = try #require(alarms[1].trigger as? AlarmTriggerRelative)
        #expect(secondTrigger.offset == KotlinDuration.rawValue(fromTimeInterval: -86400))
        #expect(secondTrigger.relatedTo == TriggerRelation.start)
    }

    @Test
    func creatingEventIncludesPrefilledAlarms() throws {
        let draft = try makeDraft(alarms: [EventAlarmDraft(offset: .oneHourBefore, action: .email)])

        let editData = try draft.toEventEditData()
        let alarms = try #require((editData.alarms as? AlarmListEditReplace)?.alarms)

        #expect(alarms.count == 1)
        #expect(EventAlarmDraft(sdk: alarms[0]).action == .email)
        #expect(EventAlarmDraft(sdk: alarms[0]).trigger == draft.alarms[0].trigger)
    }

    @Test
    func disablingAllAlarmsReplacesWithEmptyList() throws {
        let alarm = EventAlarmDraft(offset: .oneHourBefore)
        let storedEditData = try makeStoredEditData(alarms: [alarm])
        var draft = try makeDraft(alarms: [alarm])
        draft.alarms[0] = alarm.with(offset: .none)

        let editData = try draft.toEventEditData(preserving: storedEditData)
        let alarms = try #require((editData.alarms as? AlarmListEditReplace)?.alarms)

        #expect(alarms.isEmpty)
    }

    @Test
    func replacingAlarmsPreservesRepetitionAndMetadata() throws {
        let sdkAlarm = EventAlarm(
            action: AlarmActionEmail(),
            trigger: AlarmTriggerRelative(offset: KotlinDuration.rawValue(fromTimeInterval: -300), relatedTo: .end),
            description: "description",
            summary: "summary",
            attendees: ["attendee@example.com"],
            attachments: ["attachment"],
            uid: "alarm-uid",
            repetition: AlarmRepetition(count: 3, interval: KotlinDuration.rawValue(fromTimeInterval: 120))
        )
        let alarm = EventAlarmDraft(sdk: sdkAlarm)
        #expect(alarm.uid == "alarm-uid")
        #expect(alarm.repetition == EventAlarmDraft.Repetition(count: 3, interval: 120))
        let storedEditData = try makeStoredEditData(alarms: [alarm])
        var draft = try makeDraft(alarms: [alarm])
        draft.alarms.append(EventAlarmDraft(offset: .oneDayBefore))

        let editData = try draft.toEventEditData(preserving: storedEditData)
        let alarms = try #require((editData.alarms as? AlarmListEditReplace)?.alarms)

        #expect(alarms.count == 2)
        #expect(alarms[0] == sdkAlarm)

        let preset = try #require(alarm.with(offset: .oneHourBefore).toSDK())
        #expect(preset.uid as? String == "alarm-uid")
        #expect(preset.repetition == sdkAlarm.repetition)
        #expect(preset.attendees == sdkAlarm.attendees)

        let custom = try #require(alarm.with(
            trigger: .relative(offset: -7200, relatedTo: .start),
            action: .display
        ).toSDK())
        #expect(custom.uid as? String == "alarm-uid")
        #expect(custom.repetition == sdkAlarm.repetition)
        #expect(custom.description_ == sdkAlarm.description_)
        #expect(custom.summary == sdkAlarm.summary)
        #expect(custom.attendees == sdkAlarm.attendees)
        #expect(custom.attachments == sdkAlarm.attachments)
        #expect(custom.action is AlarmActionDisplay)
        #expect(EventAlarmDraft(sdk: custom).trigger == .relative(offset: -7200, relatedTo: .start))
    }

    @Test
    func eventAlarmDraftFromDetailsPreservesMetadata() throws {
        let alarm = EventAlarmDraft(
            action: .unknown("X-CUSTOM"),
            trigger: .absolute(instant: Date(timeIntervalSince1970: 1_800_000_000)),
            attachments: ["attachment"],
            attendees: ["attendee@example.com"],
            description: "description",
            summary: "summary",
            uid: "alarm-uid",
            repetition: .init(count: 2, interval: 60)
        )
        let sdkAlarm = try #require(alarm.toSDK())
        let displayedAlarm = UIEventAlarm(sdk: sdkAlarm)
        let editedAlarm = displayedAlarm.draft.with(offset: .oneHourBefore)
        let savedAlarm = try #require(editedAlarm.toSDK())

        #expect(displayedAlarm.draft == alarm)
        #expect(editedAlarm.id == displayedAlarm.id)
        #expect(savedAlarm.uid as? String == "alarm-uid")
        #expect(savedAlarm.repetition == sdkAlarm.repetition)
        #expect(UIAlarmAction(sdk: savedAlarm.action) == .unknown("X-CUSTOM"))
        #expect(savedAlarm.attendees == sdkAlarm.attendees)
        #expect(savedAlarm.attachments == sdkAlarm.attachments)
        #expect(savedAlarm.description_ == sdkAlarm.description_)
        #expect(savedAlarm.summary == sdkAlarm.summary)
    }

    @Test
    func unchangedAlarmsPreserveOriginalEditData() throws {
        let storedEditData = try makeStoredEditData(alarms: [EventAlarmDraft(offset: .oneHourBefore)])
        let draft = try makeDraft(alarms: [EventAlarmDraft(offset: .oneHourBefore)])

        let editData = try draft.toEventEditData(preserving: storedEditData)

        #expect(editData.alarms is AlarmListEditPreserve)
    }

    @Test
    func editedAlarmsAreReplaced() throws {
        let storedEditData = try makeStoredEditData(alarms: [EventAlarmDraft(offset: .oneHourBefore)])
        var draft = try makeDraft(alarms: [EventAlarmDraft(offset: .oneHourBefore)])
        draft.alarms.removeLast()
        draft.alarms.append(EventAlarmDraft(offset: .fiveMinutesBefore))

        let editData = try draft.toEventEditData(preserving: storedEditData)
        let alarms = try #require((editData.alarms as? AlarmListEditReplace)?.alarms)

        #expect(alarms.count == 1)
        let trigger = try #require(alarms[0].trigger as? AlarmTriggerRelative)
        #expect(trigger.offset == KotlinDuration.rawValue(fromTimeInterval: -300))
    }

    @Test
    func alarmOffsetsUseKotlinDurationEncoding() throws {
        // Kotlin encodes 15 minutes as nanoseconds shifted left by one bit.
        let fifteenMinutesBefore: Int64 = -1_800_000_000_000
        let alarm = EventAlarmDraft(offset: .fifteenMinutesBefore)

        let sdkAlarm = try #require(alarm.toSDK())
        let trigger = try #require(sdkAlarm.trigger as? AlarmTriggerRelative)

        #expect(trigger.offset == fifteenMinutesBefore)
        #expect(EventAlarmDraft(sdk: sdkAlarm).trigger == .relative(offset: -900, relatedTo: .start))
        #expect(KotlinDuration.timeInterval(fromRawValue: (-900_000 << 1) | 1) == -900)
    }

    @Test
    func withOffsetRebuildsTriggerAndPreservesOtherFields() {
        let alarm = EventAlarmDraft(
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
    func withOffsetPreservesIdentity() {
        let alarm = EventAlarmDraft(offset: .fiveMinutesBefore)

        #expect(alarm.with(offset: .oneHourBefore).id == alarm.id)
        let equivalentAlarm = EventAlarmDraft(offset: .fiveMinutesBefore)
        #expect(equivalentAlarm.id != alarm.id)
        #expect(equivalentAlarm != alarm)
    }

    @Test
    func selectingNoneClearsAlarmTrigger() {
        let alarm = EventAlarmDraft(offset: .fiveMinutesBefore)

        let updated = alarm.with(offset: .none)

        #expect(updated.action == .display)
        #expect(updated.trigger == nil)
        #expect(updated.offset == .none)
    }

    @Test(arguments: AlarmOffset.allCases.filter { $0 != .none })
    func presetRoundTripsThroughSDK(offset: AlarmOffset) throws {
        let alarm = EventAlarmDraft(offset: offset)

        let sdkAlarm = try #require(alarm.toSDK())
        let roundTripped = EventAlarmDraft(sdk: sdkAlarm)

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

    private func makeDraft(alarms: [EventAlarmDraft] = []) throws -> EventDraft {
        try EventDraft(
            calendarId: "calendar-id",
            startDate: date("2026-09-22T10:10:00Z"),
            endDate: date("2026-09-22T11:10:00Z"),
            alarms: alarms
        )
    }

    /// Simulates the SDK handing back stored alarms untouched when re-editing an event.
    private func makeStoredEditData(alarms: [EventAlarmDraft]) throws -> EventEditData {
        let editData = try makeDraft(alarms: alarms).toEventEditData()
        return editData.doCopy(
            title: editData.title,
            timing: editData.timing,
            location: editData.location,
            description: editData.description_,
            timeBlocking: editData.timeBlocking,
            calendarId: editData.calendarId,
            eventColor: editData.eventColor,
            alarms: AlarmListEditPreserve(),
            attendees: editData.attendees,
            organizer: editData.organizer
        )
    }

    private func date(_ value: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: value))
    }
}
