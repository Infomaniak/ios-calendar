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

// TODO: Function name should follow KMP function name
public protocol EventAlarmEventsProviding: Sendable {
    func eventAlarmsToDisplay(range: Range<Date>) async throws -> [MultiplatformCalendar.Event]
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

    struct AlarmContext {
        let event: MultiplatformCalendar.Event
        let alarm: EventAlarm
    }

    private let windowSize: TimeInterval
    private let calendar: Foundation.Calendar
    private let eventsProvider: EventAlarmEventsProviding
    private let notificationCenter: EventAlarmNotificationCenter

    public init(
        windowSize: TimeInterval = EventAlarmNotificationsService.defaultWindowSize,
        calendar: Foundation.Calendar = .current,
        eventsProvider: EventAlarmEventsProviding,
        notificationCenter: EventAlarmNotificationCenter = UNUserNotificationCenter.current()
    ) {
        self.windowSize = windowSize
        self.calendar = calendar
        self.eventsProvider = eventsProvider
        self.notificationCenter = notificationCenter
    }

    public func scheduleNotificationsForEventAlarms() async {
        let rangeOfEvents = Date.now ..< Date.now.addingTimeInterval(windowSize)
        guard let alarmContexts = await alarmContexts(rangeOfEvents) else {
            return
        }

        let pendingNotifications = await notificationCenter.pendingNotificationRequests()

        let diff = diffAlarmsAndPendingNotifications(alarms: alarmContexts, pendingNotifications: pendingNotifications)
        await unscheduleStaleNotifications(diff.toUnschedule)
        await scheduleNotificationsForEvents(diff.toSchedule)
    }

    private func alarmContexts(_ range: Range<Date>) async -> [AlarmContext]? {
        let events: [MultiplatformCalendar.Event]
        do {
            events = try await eventsProvider.eventAlarmsToDisplay(range: range)
        } catch {
            Logger.general.error("Failed to fetch events for alarm notifications: \(error)")
            SentrySDK.capture(error: error)
            return nil
        }

        var eventAlarms = [AlarmContext]()
        for event in events {
            for alarm in event.alarms {
                eventAlarms.append(AlarmContext(event: event, alarm: alarm))
            }
        }

        return Array(eventAlarms.prefix(EventAlarmNotificationsService.maximumNotificationsToSchedule))
    }

    private func diffAlarmsAndPendingNotifications(
        alarms: [AlarmContext], pendingNotifications: [UNNotificationRequest]
    ) -> (toSchedule: [AlarmContext], toUnschedule: [UNNotificationRequest]) {
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

    private func scheduleNotificationsForEvents(_ eventAlarms: [AlarmContext]) async {
        guard !eventAlarms.isEmpty else { return }

        for eventAlarm in eventAlarms {
            guard let request = generateNotificationRequestForAlarm(eventAlarm) else { continue }

            do {
                try await notificationCenter.add(request)
            } catch {
                Logger.general.error("Failed to schedule notification for event \(eventAlarm.event.masterEventIdValue): \(error)")
                SentrySDK.capture(error: error)
            }
        }
    }

    private func generateNotificationRequestForAlarm(_ alarmContext: AlarmContext) -> UNNotificationRequest? {
        guard let trigger = calendarTriggerOfAlarm(alarmContext) else {
            return nil
        }

        let content = UNMutableNotificationContent()
        content.title = alarmContext.event.title
        content.body = alarmContext.alarm.description_ ?? alarmContext.event.location
            ?? CalendarResourcesStrings.notificationDefaultDescription
        content.sound = .default
        content.categoryIdentifier = NotificationsHelper.CategoryIdentifier.eventAlarm
        content.userInfo = [
            NotificationsHelper.UserInfoKeys.eventId: alarmContext.event.masterEventIdValue
        ]
        return UNNotificationRequest(identifier: notificationID(for: alarmContext), content: content, trigger: trigger)
    }

    // TODO: alarm date can probably be computed by KMP?
    private func calendarTriggerOfAlarm(_ alarmContext: AlarmContext) -> UNCalendarNotificationTrigger? {
        if let absoluteTrigger = alarmContext.alarm.trigger as? AlarmTriggerAbsolute {
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: absoluteTrigger.instant.date
            )

            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        if let relativeTrigger = alarmContext.alarm.trigger as? AlarmTriggerRelative {
            let referenceDate: Date?
            switch relativeTrigger.relatedTo {
            case .start:
                referenceDate = alarmContext.event.timing.start.date(timezone: alarmContext.event.timing.startTimeZone)
            case .end:
                referenceDate = alarmContext.event.timing.end.date(timezone: alarmContext.event.timing.endTimeZone)
            }

            guard let referenceDate else { return nil }
            let triggerDate = referenceDate.addingTimeInterval(TimeInterval(relativeTrigger.offset))
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: triggerDate
            )

            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        return nil
    }

    // TODO: KMP should compute a unique identifier for each alarm
    private func notificationID(for alarmContext: AlarmContext) -> String {
        return "\(Self.notificationIDPrefix)\(alarmContext.event.masterEventIdValue):\(alarmContext.alarm.hash())"
    }
}
