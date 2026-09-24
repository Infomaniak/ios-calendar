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

public final class EventAlarmNotificationsService: Sendable {
    private static let notificationIDPrefix = "event-alarm:"
    private static let maximumNotificationsToSchedule = 50

    public static let defaultWindowSize: TimeInterval = 60 * 60 * 24 * 3 // 3 days

    private let windowSize: TimeInterval

    private let calendar: Foundation.Calendar
    private let eventsProvider: EventAlarmEventsProviding
    private let notificationCenter: EventAlarmNotificationCenter

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
        let rangeOfEvents = Date.now ..< Date.now.addingTimeInterval(windowSize)
        let upcomingAlarms: [UpcomingAlarm]
        do {
            upcomingAlarms = try await eventsProvider.eventAlarmsToDisplay(
                range: rangeOfEvents, limit: Self.maximumNotificationsToSchedule
            )
        } catch {
            Logger.general.error("Failed to fetch upcoming alarms for notifications: \(error)")
            SentrySDK.capture(error: error)
            return
        }

        let pendingNotifications = await notificationCenter.pendingNotificationRequests()

        let diff = diffAlarmsAndPendingNotifications(alarms: upcomingAlarms, pendingNotifications: pendingNotifications)
        await unscheduleStaleNotifications(diff.toUnschedule)
        await scheduleNotificationsForAlarms(diff.toSchedule)
    }

    private func diffAlarmsAndPendingNotifications(
        alarms: [UpcomingAlarm], pendingNotifications: [UNNotificationRequest]
    ) -> (toSchedule: [UpcomingAlarm], toUnschedule: [UNNotificationRequest]) {
        let expectedNotificationIDs = Set(alarms.map { notificationID(for: $0) })
        let pendingNotificationIDs = Set(pendingNotifications.map(\.identifier))

        let toSchedule = alarms.filter {
            !pendingNotificationIDs.contains(notificationID(for: $0))
        }
        let toUnschedule = pendingNotifications.filter {
            $0.identifier.hasPrefix(Self.notificationIDPrefix) && !expectedNotificationIDs.contains($0.identifier)
        }

        return (toSchedule, toUnschedule)
    }

    private func unscheduleStaleNotifications(_ notifications: [UNNotificationRequest]) async {
        guard !notifications.isEmpty else { return }

        let identifiers = notifications.map { $0.identifier }
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func scheduleNotificationsForAlarms(_ upcomingAlarms: [UpcomingAlarm]) async {
        guard !upcomingAlarms.isEmpty else { return }

        for upcomingAlarm in upcomingAlarms {
            let request = generateNotificationRequestForAlarm(upcomingAlarm)

            do {
                try await notificationCenter.add(request)
            } catch {
                Logger.general.error("Failed to schedule notification for \(upcomingAlarm.event.masterEventIdValue): \(error)")
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
        content.title = upcomingAlarm.event.title
        content.body = upcomingAlarm.alarm.description_ ?? upcomingAlarm.event.location
            ?? CalendarResourcesStrings.notificationDefaultDescription
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
