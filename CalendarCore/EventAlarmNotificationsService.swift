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

import CalendarResources
import Foundation
import InfomaniakDI
import MultiplatformCalendar
import OSLog
import Sentry
import UserNotifications

public protocol EventAlarmEventsProviding: Sendable {
    func eventAlarmsToDisplay(range: Range<Date>, limit: Int) async throws -> [UpcomingAlarm]
}

public struct EventAlarmEventsProvider: EventAlarmEventsProviding {
    public init() {}

    public func eventAlarmsToDisplay(range: Range<Date>, limit: Int) async throws -> [UpcomingAlarm] {
        let from = range.lowerBound.kotlinInstant
        let horizon = range.upperBound.kotlinInstant.minus(other: from)

        @InjectService var calendarSDK: CalendarCoreGraph
        for await upcomingAlarms in calendarSDK.calendarManager.observeUpcomingAlarms(
            limit: Int32(limit), horizon: horizon, from: from
        ) {
            return upcomingAlarms
        }

        return []
    }
}

private extension Date {
    var kotlinInstant: KotlinInstant {
        KotlinInstant.companion.fromEpochMilliseconds(epochMilliseconds: Int64(timeIntervalSince1970 * 1000))
    }
}

public protocol EventAlarmNotificationCenter: Sendable {
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) async
}

extension UNUserNotificationCenter: EventAlarmNotificationCenter {}

private actor RefreshActor {
    private var runningTask: Task<Void, Never>?
    private var generation = 0

    func run(_ refresh: @escaping @Sendable () async -> Void) async {
        generation += 1
        let currentGeneration = generation

        let previousTask = runningTask
        previousTask?.cancel()

        let task = Task {
            await previousTask?.value

            guard !Task.isCancelled else { return }
            await refresh()
        }

        runningTask = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }

        if generation == currentGeneration {
            runningTask = nil
        }
    }
}

public final class EventAlarmNotificationsService: Sendable {
    private static let notificationIDPrefix = "event-alarm:"
    private static let maximumNotificationsToSchedule = 50

    public static let defaultWindowSize: TimeInterval = 60 * 60 * 24 * 3 // 3 days

    private let windowSize: TimeInterval

    private let calendar: Foundation.Calendar
    private let eventsProvider: EventAlarmEventsProviding
    private let notificationCenter: EventAlarmNotificationCenter
    private let refreshActor = RefreshActor()

    public init(
        windowSize: TimeInterval = EventAlarmNotificationsService.defaultWindowSize,
        calendar: Foundation.Calendar = .current,
        eventsProvider: EventAlarmEventsProviding = EventAlarmEventsProvider(),
        notificationCenter: EventAlarmNotificationCenter = UNUserNotificationCenter.current()
    ) {
        self.windowSize = windowSize
        self.calendar = calendar
        self.eventsProvider = eventsProvider
        self.notificationCenter = notificationCenter
    }

    public func scheduleNotificationsForEventAlarms() async {
        await refreshActor.run { [self] in
            await scheduleAlarms()
        }
    }

    private func scheduleAlarms() async {
        let rangeOfEvents = Date.now ..< Date.now.addingTimeInterval(windowSize)
        guard let upcomingAlarms = await upcomingAlarms(range: rangeOfEvents, limit: Self.maximumNotificationsToSchedule) else {
            return
        }

        guard !Task.isCancelled else { return }
        let pendingNotifications = await notificationCenter.pendingNotificationRequests()

        guard !Task.isCancelled else { return }
        let diff = diffAlarmsAndPendingNotifications(alarms: upcomingAlarms, pendingNotifications: pendingNotifications)

        guard !Task.isCancelled else { return }
        await unscheduleStaleNotifications(diff.toUnschedule)
        guard !Task.isCancelled else { return }
        await scheduleNotificationsForAlarms(diff.toSchedule)
    }

    private func upcomingAlarms(range: Range<Date>, limit: Int) async -> [UpcomingAlarm]? {
        do {
            return try await eventsProvider.eventAlarmsToDisplay(range: range, limit: limit)
        } catch {
            guard !Task.isCancelled else { return nil }
            Logger.general.error("Failed to fetch upcoming alarms for notifications: \(error)")
            SentrySDK.capture(error: error)
            return nil
        }
    }

    private func diffAlarmsAndPendingNotifications(
        alarms: [UpcomingAlarm], pendingNotifications: [UNNotificationRequest]
    ) -> (toSchedule: [UNNotificationRequest], toUnschedule: [UNNotificationRequest]) {
        let expectedRequests = alarms.map(generateNotificationRequestForAlarm)

        let expectedNotificationIDs = Set(expectedRequests.map(\.identifier))
        let pendingByID = Dictionary(pendingNotifications.map { ($0.identifier, $0) }) { _, latest in latest }

        let toSchedule = expectedRequests.filter { request in
            guard let pending = pendingByID[request.identifier] else { return true }
            return needsUpdate(pending, with: request)
        }
        let toUnschedule = pendingNotifications.filter {
            $0.identifier.hasPrefix(Self.notificationIDPrefix) && !expectedNotificationIDs.contains($0.identifier)
        }

        return (toSchedule, toUnschedule)
    }

    private func needsUpdate(_ pending: UNNotificationRequest, with request: UNNotificationRequest) -> Bool {
        return pending.content.title != request.content.title || pending.content.body != request.content.body
    }

    private func unscheduleStaleNotifications(_ notifications: [UNNotificationRequest]) async {
        guard !notifications.isEmpty else { return }

        let identifiers = notifications.map { $0.identifier }
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func scheduleNotificationsForAlarms(_ requests: [UNNotificationRequest]) async {
        for request in requests {
            guard !Task.isCancelled else { return }

            do {
                try await notificationCenter.add(request)
            } catch {
                guard !Task.isCancelled else { return }
                Logger.general.error("Failed to schedule notification for \(request.identifier): \(error)")
                SentrySDK.capture(error: error)
            }
        }
    }

    private func generateNotificationRequestForAlarm(_ upcomingAlarm: UpcomingAlarm) -> UNNotificationRequest {
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: upcomingAlarm.firesAt.toNSDate()
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let content = UNMutableNotificationContent()
        content.body = upcomingAlarm.event.title
        content.sound = .default
        content.categoryIdentifier = NotificationsHelper.CategoryIdentifier.eventAlarm
        content.userInfo = [
            NotificationsHelper.UserInfoKeys.eventId: upcomingAlarm.event.masterEventIdValue
        ]

        return UNNotificationRequest(identifier: notificationID(for: upcomingAlarm), content: content, trigger: trigger)
    }

    private func notificationID(for upcomingAlarm: UpcomingAlarm) -> String {
        return "\(Self.notificationIDPrefix)\(upcomingAlarm.idValue)"
    }
}
