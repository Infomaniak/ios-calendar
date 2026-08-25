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
import UserNotifications

struct EventAlarmNotificationsServiceTests {
    @Test func reconcilesOnlyEventAlarmNotifications() async {
        let existingEvent = EventAlarmTestFixtures.event(id: "existing-event")
        let missingEvent = EventAlarmTestFixtures.event(id: "missing-event")
        let existingIdentifier = EventAlarmTestFixtures.notificationIdentifier(for: existingEvent)
        let notificationCenter = EventAlarmTestNotificationCenter(pendingRequests: [
            EventAlarmTestFixtures.notificationRequest(identifier: existingIdentifier),
            EventAlarmTestFixtures.notificationRequest(identifier: "event-alarm:stale"),
            EventAlarmTestFixtures.notificationRequest(identifier: "another-feature")
        ])
        let eventsProvider = EventAlarmTestEventsProvider(events: [existingEvent, missingEvent])
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let snapshot = await notificationCenter.snapshot()
        #expect(snapshot.addedRequests.map(\.identifier) == [
            EventAlarmTestFixtures.notificationIdentifier(for: missingEvent)
        ])
        #expect(snapshot.removedIdentifiers == ["event-alarm:stale"])
    }

    @Test func leavesPendingNotificationsUnchangedWhenFetchingEventsFails() async {
        let notificationCenter = EventAlarmTestNotificationCenter(pendingRequests: [
            EventAlarmTestFixtures.notificationRequest(identifier: "event-alarm:existing")
        ])
        let eventsProvider = EventAlarmTestEventsProvider(error: EventAlarmTestError.fetchFailed)
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let snapshot = await notificationCenter.snapshot()
        #expect(snapshot.addedRequests.isEmpty)
        #expect(snapshot.removedIdentifiers.isEmpty)
        #expect(snapshot.pendingRequestsCallCount == 0)
    }

    @Test func requestsEventsForConfiguredWindow() async throws {
        let windowSize: TimeInterval = 7_200
        let eventsProvider = EventAlarmTestEventsProvider(events: [])
        let notificationCenter = EventAlarmTestNotificationCenter()
        let service = EventAlarmNotificationsService(
            windowSize: windowSize,
            calendar: Calendar.current,
            eventsProvider: eventsProvider,
            notificationCenter: notificationCenter
        )

        let beforeScheduling = Date.now
        await service.scheduleNotificationsForEventAlarms()
        let afterScheduling = Date.now

        let requestedRanges = await eventsProvider.requestedRanges
        let requestedRange = try #require(requestedRanges.first)
        #expect(requestedRanges.count == 1)
        #expect(requestedRange.lowerBound >= beforeScheduling)
        #expect(requestedRange.lowerBound <= afterScheduling)
        #expect(requestedRange.upperBound >= beforeScheduling.addingTimeInterval(windowSize))
        #expect(requestedRange.upperBound <= afterScheduling.addingTimeInterval(windowSize))
    }

    @Test func schedulesRelativeAlarmAtOffsetWithExpectedContent() async throws {
        let event = EventAlarmTestFixtures.event(
            id: "event-id",
            title: "Team meeting",
            location: "Meeting room",
            alarmDescription: "Join the meeting",
            offset: -300,
            relatedTo: .start
        )
        let notificationCenter = EventAlarmTestNotificationCenter()
        let eventsProvider = EventAlarmTestEventsProvider(events: [event])
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let request = try #require(await notificationCenter.snapshot().addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        let referenceDate = try #require(event.timing.start.swiftDate)
        let expectedDate = referenceDate.addingTimeInterval(-300)

        #expect(trigger.dateComponents == Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: expectedDate
        ))
        #expect(request.content.title == "Team meeting")
        #expect(request.content.body == "Join the meeting")
        #expect(request.content.categoryIdentifier == NotificationsHelper.CategoryIdentifier.eventAlarm)
        #expect(request.content.userInfo[NotificationsHelper.UserInfoKeys.eventId] as? String == event.masterEventIdValue)
    }

    @Test func limitsScheduledNotificationsToSystemCapacity() async {
        let events = (0 ... 64).map { EventAlarmTestFixtures.event(id: "event-\($0)") }
        let notificationCenter = EventAlarmTestNotificationCenter()
        let eventsProvider = EventAlarmTestEventsProvider(events: events)
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let snapshot = await notificationCenter.snapshot()
        #expect(snapshot.addedRequests.count == 64)
    }

    private func makeService(
        eventsProvider: EventAlarmTestEventsProvider,
        notificationCenter: EventAlarmTestNotificationCenter
    ) -> EventAlarmNotificationsService {
        EventAlarmNotificationsService(
            calendar: Calendar.current,
            eventsProvider: eventsProvider,
            notificationCenter: notificationCenter
        )
    }
}

private actor EventAlarmTestNotificationCenter: EventAlarmNotificationCenter {
    struct Snapshot {
        let addedRequests: [UNNotificationRequest]
        let removedIdentifiers: [String]
        let pendingRequestsCallCount: Int
    }

    private let pendingRequests: [UNNotificationRequest]
    private var addedRequests = [UNNotificationRequest]()
    private var removedIdentifiers = [String]()
    private var pendingRequestsCallCount = 0

    init(pendingRequests: [UNNotificationRequest] = []) {
        self.pendingRequests = pendingRequests
    }

    func pendingNotificationRequests() -> [UNNotificationRequest] {
        pendingRequestsCallCount += 1
        return pendingRequests
    }

    func add(_ request: UNNotificationRequest) {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }

    func snapshot() -> Snapshot {
        Snapshot(
            addedRequests: addedRequests,
            removedIdentifiers: removedIdentifiers,
            pendingRequestsCallCount: pendingRequestsCallCount
        )
    }
}

private actor EventAlarmTestEventsProvider: EventAlarmEventsProviding {
    private let events: [MultiplatformCalendar.Event]
    private let error: (any Error)?
    private(set) var requestedRanges = [Range<Date>]()

    init(events: [MultiplatformCalendar.Event] = [], error: (any Error)? = nil) {
        self.events = events
        self.error = error
    }

    func eventAlarmsToDisplay(range: Range<Date>) throws -> [MultiplatformCalendar.Event] {
        requestedRanges.append(range)
        if let error {
            throw error
        }
        return events
    }
}

private enum EventAlarmTestError: Error {
    case fetchFailed
}

private enum EventAlarmTestFixtures {
    static func event(
        id: String,
        title: String? = nil,
        location: String? = nil,
        alarmDescription: String? = nil,
        offset: Int64 = -300,
        relatedTo: TriggerRelation = .start
    ) -> MultiplatformCalendar.Event {
        let alarm = EventAlarm(
            action: AlarmActionDisplay(),
            trigger: AlarmTriggerRelative(offset: offset, relatedTo: relatedTo),
            description: alarmDescription,
            summary: nil,
            attendees: [],
            attachments: []
        )
        let startDate = Kotlinx_datetimeLocalDateTime(
            year: 2027,
            month: 1,
            day: 15,
            hour: 10,
            minute: 0,
            second: 0,
            nanosecond: 0
        )
        let endDate = Kotlinx_datetimeLocalDateTime(
            year: 2027,
            month: 1,
            day: 15,
            hour: 11,
            minute: 0,
            second: 0,
            nanosecond: 0
        )
        let timing = EventTiming(
            start: startDate,
            end: endDate,
            startTimeZone: nil,
            endTimeZone: nil,
            isAllDay: false
        )
        let themedColor = ThemedColor(light: 0, dark: 0)
        let colors = EventColors(
            calendarSourceColor: 0,
            sourceColor: 0,
            containerColor: 0,
            onContainerColor: themedColor,
            containerVariantColor: 0,
            onContainerVariantColor: themedColor
        )
        return MultiplatformCalendar.Event(
            masterEventId: id,
            occurrenceId: id,
            calendarId: "calendar-id",
            accountId: 0,
            title: title ?? id,
            description: nil,
            location: location,
            status: .confirmed,
            classification: nil,
            categories: [],
            timing: timing,
            lastModified: nil,
            attendees: [],
            organizer: nil,
            colors: colors,
            canEdit: true,
            alarms: [alarm]
        )
    }

    static func notificationRequest(identifier: String) -> UNNotificationRequest {
        UNNotificationRequest(
            identifier: identifier,
            content: UNMutableNotificationContent(),
            trigger: nil
        )
    }

    static func notificationIdentifier(for event: MultiplatformCalendar.Event) -> String {
        "event-alarm:\(event.masterEventIdValue):\(event.alarms[0].hash())"
    }
}
