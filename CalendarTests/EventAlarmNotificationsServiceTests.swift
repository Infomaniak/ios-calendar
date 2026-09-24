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
        let existingAlarm = EventAlarmTestFixtures.upcomingAlarm(id: "existing-alarm")
        let missingAlarm = EventAlarmTestFixtures.upcomingAlarm(id: "missing-alarm")
        let existingIdentifier = EventAlarmTestFixtures.notificationIdentifier(for: existingAlarm)
        let notificationCenter = EventAlarmTestNotificationCenter(pendingRequests: [
            EventAlarmTestFixtures.notificationRequest(identifier: existingIdentifier),
            EventAlarmTestFixtures.notificationRequest(identifier: "event-alarm:stale"),
            EventAlarmTestFixtures.notificationRequest(identifier: "another-feature")
        ])
        let eventsProvider = EventAlarmTestEventsProvider(upcomingAlarms: [existingAlarm, missingAlarm])
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let snapshot = await notificationCenter.snapshot()
        #expect(snapshot.addedRequests.map(\.identifier) == [
            EventAlarmTestFixtures.notificationIdentifier(for: missingAlarm)
        ])
        #expect(snapshot.removedIdentifiers == ["event-alarm:stale"])
    }

    @Test func leavesPendingNotificationsUnchangedWhenFetchingAlarmsFails() async {
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

    @Test func requestsAlarmsForConfiguredWindowAndLimit() async throws {
        let windowSize: TimeInterval = 7200
        let eventsProvider = EventAlarmTestEventsProvider(upcomingAlarms: [])
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

        let requests = await eventsProvider.requests
        let request = try #require(requests.first)
        #expect(requests.count == 1)
        #expect(request.range.lowerBound >= beforeScheduling)
        #expect(request.range.lowerBound <= afterScheduling)
        #expect(request.range.upperBound >= beforeScheduling.addingTimeInterval(windowSize))
        #expect(request.range.upperBound <= afterScheduling.addingTimeInterval(windowSize))
        #expect(request.limit == 50)
    }

    @Test func schedulesAlarmAtFiringDateWithExpectedContent() async throws {
        let firesAt = Date(timeIntervalSince1970: 1_800_000_000)
        let upcomingAlarm = EventAlarmTestFixtures.upcomingAlarm(
            id: "alarm-id",
            eventId: "event-id",
            firesAt: firesAt,
            title: "Team meeting",
            location: "Meeting room",
            alarmDescription: "Join the meeting"
        )
        let notificationCenter = EventAlarmTestNotificationCenter()
        let eventsProvider = EventAlarmTestEventsProvider(upcomingAlarms: [upcomingAlarm])
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let request = try #require(await notificationCenter.snapshot().addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)

        #expect(request.identifier == "event-alarm:alarm-id")
        #expect(trigger.dateComponents == Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: firesAt
        ))
        #expect(request.content.title == "Team meeting")
        #expect(request.content.body == "Join the meeting")
        #expect(request.content.categoryIdentifier == NotificationsHelper.CategoryIdentifier.eventAlarm)
        #expect(request.content.userInfo[NotificationsHelper.UserInfoKeys.eventId] as? String == "event-id")
    }

    @Test func fallsBackToEventLocationWhenAlarmHasNoDescription() async throws {
        let upcomingAlarm = EventAlarmTestFixtures.upcomingAlarm(id: "alarm-id", location: "Meeting room")
        let notificationCenter = EventAlarmTestNotificationCenter()
        let eventsProvider = EventAlarmTestEventsProvider(upcomingAlarms: [upcomingAlarm])
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let request = try #require(await notificationCenter.snapshot().addedRequests.first)
        #expect(request.content.body == "Meeting room")
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
    struct Request {
        let range: Range<Date>
        let limit: Int
    }

    private let upcomingAlarms: [UpcomingAlarm]
    private let error: (any Error)?
    private(set) var requests = [Request]()

    init(upcomingAlarms: [UpcomingAlarm] = [], error: (any Error)? = nil) {
        self.upcomingAlarms = upcomingAlarms
        self.error = error
    }

    func eventAlarmsToDisplay(range: Range<Date>, limit: Int) throws -> [UpcomingAlarm] {
        requests.append(Request(range: range, limit: limit))
        if let error {
            throw error
        }
        return upcomingAlarms
    }
}

private enum EventAlarmTestError: Error {
    case fetchFailed
}

private enum EventAlarmTestFixtures {
    static func upcomingAlarm(
        id: String,
        eventId: String? = nil,
        firesAt: Date = Date(timeIntervalSince1970: 1_800_000_000),
        title: String? = nil,
        location: String? = nil,
        alarmDescription: String? = nil
    ) -> UpcomingAlarm {
        let alarm = EventAlarm(
            action: AlarmActionDisplay(),
            trigger: AlarmTriggerRelative(offset: -300, relatedTo: .start),
            description: alarmDescription,
            summary: nil,
            attendees: [],
            attachments: []
        )
        let startDate = LocalDateTime(
            year: 2027,
            month: 1,
            day: 15,
            hour: 10,
            minute: 0,
            second: 0,
            nanosecond: 0
        )
        let endDate = LocalDateTime(
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
        let eventId = eventId ?? id
        let event = MultiplatformCalendar.Event(
            masterEventId: eventId,
            occurrenceId: OccurrenceId.Master(masterId: eventId),
            calendarId: "calendar-id",
            accountId: 0,
            title: title ?? eventId,
            description: nil,
            location: location,
            status: .confirmed,
            timeBlocking: nil,
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
        let firesAtInstant = KotlinInstant.companion.fromEpochMilliseconds(
            epochMilliseconds: Int64(firesAt.timeIntervalSince1970 * 1000)
        )
        return UpcomingAlarm(id: id, firesAt: firesAtInstant, alarm: alarm, event: event)
    }

    static func notificationRequest(identifier: String) -> UNNotificationRequest {
        UNNotificationRequest(
            identifier: identifier,
            content: UNMutableNotificationContent(),
            trigger: nil
        )
    }

    static func notificationIdentifier(for upcomingAlarm: UpcomingAlarm) -> String {
        "event-alarm:\(upcomingAlarm.idValue)"
    }
}
