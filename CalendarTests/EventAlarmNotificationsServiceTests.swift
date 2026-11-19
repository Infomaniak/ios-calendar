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
import CalendarResources
import Foundation
import MultiplatformCalendar
import Testing
import UserNotifications

struct EventAlarmNotificationsServiceTests {
    @Test func reconcilesOnlyEventAlarmNotifications() async throws {
        let existingAlarm = EventAlarmTestFixtures.upcomingAlarm(id: "existing-alarm")
        let missingAlarm = EventAlarmTestFixtures.upcomingAlarm(id: "missing-alarm")
        let initialCenter = EventAlarmTestNotificationCenter()
        await makeService(
            eventsProvider: EventAlarmTestEventsProvider(upcomingAlarms: [existingAlarm]),
            notificationCenter: initialCenter
        ).scheduleNotificationsForEventAlarms()
        let existingRequest = try #require(await initialCenter.snapshot().addedRequests.first)
        let notificationCenter = EventAlarmTestNotificationCenter(pendingRequests: [
            existingRequest,
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

    @Test func removesPendingEventAlarmsWhenNoUpcomingAlarmsRemain() async {
        let notificationCenter = EventAlarmTestNotificationCenter(pendingRequests: [
            EventAlarmTestFixtures.notificationRequest(identifier: "event-alarm:existing"),
            EventAlarmTestFixtures.notificationRequest(identifier: "another-feature")
        ])
        let eventsProvider = EventAlarmTestEventsProvider(upcomingAlarms: [])
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let snapshot = await notificationCenter.snapshot()
        #expect(snapshot.addedRequests.isEmpty)
        #expect(snapshot.removedIdentifiers == ["event-alarm:existing"])
        #expect(snapshot.pendingRequestsCallCount == 1)
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
            title: "Team meeting"
        )
        let notificationCenter = EventAlarmTestNotificationCenter()
        let eventsProvider = EventAlarmTestEventsProvider(upcomingAlarms: [upcomingAlarm])
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let request = try #require(await notificationCenter.snapshot().addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)

        #expect(request.identifier == "event-alarm:alarm-id")
        #expect(trigger.dateComponents == testCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: firesAt
        ))
        #expect(request.content.title == "Team meeting")
        #expect(request.content.categoryIdentifier == NotificationsHelper.CategoryIdentifier.eventAlarm)
        #expect(request.content.userInfo[NotificationsHelper.UserInfoKeys.occurrenceId] as? String == "event-id")
    }

    @Test func showsTimeBoundsAndLocationForTimedEvent() async throws {
        let request = try await scheduledRequest(for: EventAlarmTestFixtures.upcomingAlarm(
            id: "alarm-id",
            title: " Workshop ",
            location: "Salle Jules Verne",
            start: DateComponents(year: 2027, month: 1, day: 15, hour: 14),
            end: DateComponents(year: 2027, month: 1, day: 15, hour: 14, minute: 45)
        ))

        #expect(request.content.title == "Workshop")
        #expect(request.content.body == "14:00\u{2009}–\u{2009}14:45\nSalle Jules Verne")
    }

    @Test func showsDayAndAllDayLabelForAllDayEvent() async throws {
        let firesAt = try #require(testCalendar.date(from: DateComponents(year: 2027, month: 1, day: 15, hour: 9, minute: 41)))
        let request = try await scheduledRequest(for: EventAlarmTestFixtures.upcomingAlarm(
            id: "alarm-id",
            firesAt: firesAt,
            title: "Séminaire",
            start: DateComponents(year: 2027, month: 1, day: 15),
            end: DateComponents(year: 2027, month: 1, day: 16),
            isAllDay: true
        ))

        #expect(request.content.body == "\(relativeDay(offset: 0)) · \(CalendarResourcesStrings.allDayLabel)")
    }

    @Test func showsLocationOnSecondLineForAllDayEvent() async throws {
        let firesAt = try #require(testCalendar.date(from: DateComponents(year: 2027, month: 1, day: 15, hour: 9, minute: 41)))
        let request = try await scheduledRequest(for: EventAlarmTestFixtures.upcomingAlarm(
            id: "alarm-id",
            firesAt: firesAt,
            location: "Rue du Rhône 1, 1204 Genève",
            start: DateComponents(year: 2027, month: 1, day: 15),
            end: DateComponents(year: 2027, month: 1, day: 16),
            isAllDay: true
        ))

        #expect(request.content
            .body == "\(relativeDay(offset: 0)) · \(CalendarResourcesStrings.allDayLabel)\nRue du Rhône 1, 1204 Genève")
    }

    @Test func omitsLocationLineWhenEventHasNoLocation() async throws {
        let request = try await scheduledRequest(for: EventAlarmTestFixtures.upcomingAlarm(
            id: "alarm-id",
            start: DateComponents(year: 2027, month: 1, day: 15, hour: 9),
            end: DateComponents(year: 2027, month: 1, day: 15, hour: 10)
        ))

        #expect(request.content.body == "09:00\u{2009}–\u{2009}10:00")
    }

    @Test func showsRelativeDayWhenEventIsNotOnFiringDay() async throws {
        let firesAt = try #require(testCalendar.date(from: DateComponents(year: 2027, month: 1, day: 14, hour: 18)))
        let request = try await scheduledRequest(for: EventAlarmTestFixtures.upcomingAlarm(
            id: "alarm-id",
            firesAt: firesAt,
            start: DateComponents(year: 2027, month: 1, day: 15, hour: 9),
            end: DateComponents(year: 2027, month: 1, day: 15, hour: 10)
        ))

        #expect(request.content.body == "\(relativeDay(offset: 1)) · 09:00\u{2009}–\u{2009}10:00")
    }

    @Test func usesUntitledLabelForEventWithoutTitle() async throws {
        let request = try await scheduledRequest(for: EventAlarmTestFixtures.upcomingAlarm(id: "alarm-id", title: "  "))

        #expect(request.content.title == CalendarResourcesStrings.eventUntitledLabel)
    }

    @Test func reschedulesPendingAlarmWhenEventTitleChanged() async throws {
        let initialCenter = EventAlarmTestNotificationCenter()
        await makeService(
            eventsProvider: EventAlarmTestEventsProvider(upcomingAlarms: [
                EventAlarmTestFixtures.upcomingAlarm(id: "alarm-id", title: "Old title")
            ]),
            notificationCenter: initialCenter
        ).scheduleNotificationsForEventAlarms()
        let pendingRequest = try #require(await initialCenter.snapshot().addedRequests.first)
        let notificationCenter = EventAlarmTestNotificationCenter(pendingRequests: [pendingRequest])
        let eventsProvider = EventAlarmTestEventsProvider(upcomingAlarms: [
            EventAlarmTestFixtures.upcomingAlarm(id: "alarm-id", title: "New title")
        ])
        let service = makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)

        await service.scheduleNotificationsForEventAlarms()

        let snapshot = await notificationCenter.snapshot()
        #expect(snapshot.addedRequests.map(\.identifier) == ["event-alarm:alarm-id"])
        #expect(snapshot.addedRequests.first?.content.title == "New title")
        #expect(snapshot.removedIdentifiers.isEmpty)
    }

    private var testCalendar: Foundation.Calendar {
        var calendar = Foundation.Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "fr_CH")
        return calendar
    }

    private func relativeDay(offset: Int) -> String {
        let referenceDay = Date(timeIntervalSince1970: 1_800_000_000)
        let anchor = Calendar.current.date(byAdding: .day, value: offset, to: referenceDay) ?? referenceDay
        var style = Date.AnchoredRelativeFormatStyle(
            anchor: anchor,
            presentation: .named,
            unitsStyle: .wide,
            capitalizationContext: .beginningOfSentence
        )
        style.allowedFields = [.day]
        return style.format(referenceDay)
    }

    private func scheduledRequest(for upcomingAlarm: UpcomingAlarm) async throws -> UNNotificationRequest {
        let notificationCenter = EventAlarmTestNotificationCenter()
        let eventsProvider = EventAlarmTestEventsProvider(upcomingAlarms: [upcomingAlarm])
        await makeService(eventsProvider: eventsProvider, notificationCenter: notificationCenter)
            .scheduleNotificationsForEventAlarms()
        return try #require(await notificationCenter.snapshot().addedRequests.first)
    }

    private func makeService(
        eventsProvider: EventAlarmTestEventsProvider,
        notificationCenter: EventAlarmTestNotificationCenter
    ) -> EventAlarmNotificationsService {
        EventAlarmNotificationsService(
            calendar: testCalendar,
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
        firesAt: Date? = nil,
        title: String? = nil,
        location: String? = nil,
        start: DateComponents = DateComponents(year: 2027, month: 1, day: 15, hour: 10),
        end: DateComponents = DateComponents(year: 2027, month: 1, day: 15, hour: 11),
        isAllDay: Bool = false
    ) -> UpcomingAlarm {
        let alarm = EventAlarm(
            action: AlarmActionDisplay(),
            trigger: AlarmTriggerRelative(offset: -300, relatedTo: .start)
        )
        let startDate = localDateTime(start)
        let endDate = localDateTime(end)
        let bounds: any EventBounds = isAllDay
            ? EventBoundsAllDay(start: startDate.date, end: endDate.date)
            : EventBoundsFloating(start: startDate, end: endDate)
        let timing = EventTiming(
            bounds: bounds,
            recurrenceRule: nil,
            rDates: [],
            exDates: []
        )
        let firesAt = firesAt ?? timing.startInstantLocal().toNSDate().addingTimeInterval(-300)
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
        let event = EventSummary(
            occurrenceId: OccurrenceId.Master(masterId: eventId),
            title: title ?? eventId,
            location: location,
            status: .confirmed,
            colors: colors,
            timing: timing,
            hasAttendees: false,
            hasMeetRoom: false,
            hasPlace: location != nil,
            isBookable: false,
            isRecurring: false,
            myStatus: nil,
            canEdit: true
        )
        return UpcomingAlarm(id: id, firesAt: firesAt.instant, alarm: alarm, event: event)
    }

    private static func localDateTime(_ components: DateComponents) -> LocalDateTime {
        LocalDateTime(
            year: Int32(components.year ?? 0),
            month: Int32(components.month ?? 1),
            day: Int32(components.day ?? 1),
            hour: Int32(components.hour ?? 0),
            minute: Int32(components.minute ?? 0),
            second: 0,
            nanosecond: 0
        )
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
