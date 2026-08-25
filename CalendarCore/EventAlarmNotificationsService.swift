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

import Foundation
import MultiplatformCalendar
import OSLog
import Sentry
import UserNotifications

final class EventAlarmNotificationsService: Sendable {
    private static let notificationIDPrefix = "event-alarm:"
    private static let defaultWindowSize: TimeInterval = 60 * 60 * 24 * 3 // 3 days
    private static let maximumNotificationsToSchedule = 64

    struct AlarmContext {
        let event: MultiplatformCalendar.Event
        let alarm: EventAlarm
    }

    let windowSize: TimeInterval

    init(windowSize: TimeInterval = EventAlarmNotificationsService.defaultWindowSize) {
        self.windowSize = windowSize
    }

    func scheduleNotificationsForEventAlarms() async {
        let rangeOfEvents = Date.now ..< Date.now.addingTimeInterval(windowSize)
        let alarmContexts = await alarmContexts(rangeOfEvents)

        let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()

        let diff = diffAlarmsAndPendingNotifications(alarms: alarmContexts, pendingNotifications: pendingNotifications)
        await unscheduleStaleNotifications(diff.toUnschedule)
        await scheduleNotificationsForEvents(diff.toSchedule)
    }

    private func alarmContexts(_ range: Range<Date>) async -> [AlarmContext] {
        // TODO: KMP will return the list of events
        let events = [MultiplatformCalendar.Event]()

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
            !expectedNotificationIDs.contains($0.identifier)
        }

        return (toSchedule, toUnschedule)
    }

    private func unscheduleStaleNotifications(_ notifications: [UNNotificationRequest]) async {
        guard !notifications.isEmpty else { return }

        let identifiers = notifications.map { $0.identifier }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func scheduleNotificationsForEvents(_ eventAlarms: [AlarmContext]) async {
        guard !eventAlarms.isEmpty else { return }

        for eventAlarm in eventAlarms {
            guard let request = generateNotificationRequestForAlarm(eventAlarm) else { continue }

            do {
                try await UNUserNotificationCenter.current().add(request)
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
        content.body = alarmContext.alarm.description_ ?? alarmContext.event.location ?? "!Event Alarm"
        content.sound = .default
        content.categoryIdentifier = NotificationsHelper.CategoryIdentifier.eventAlarm
        content.userInfo = [
            NotificationsHelper.UserInfoKeys.eventId: alarmContext.event.masterEventIdValue
        ]
        return UNNotificationRequest(identifier: notificationID(for: alarmContext), content: content, trigger: trigger)
    }

    private func calendarTriggerOfAlarm(_ alarmContext: AlarmContext) -> UNCalendarNotificationTrigger? {
        // TODO: alarm date can probably be computed by KMP?
        if let absoluteTrigger = alarmContext.alarm.trigger as? AlarmTriggerAbsolute {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: absoluteTrigger.instant.date
            )

            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        if let relativeTrigger = alarmContext.alarm.trigger as? AlarmTriggerRelative {
            var referenceDate: Date
            switch relativeTrigger.relatedTo {
            case .start:
                referenceDate = alarmContext.event.timing.start.swiftDate ?? .now
            case .end:
                referenceDate = alarmContext.event.timing.end.swiftDate ?? .now
            }

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: referenceDate
            )

            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        return nil
    }

    private func notificationID(for alarmContext: AlarmContext) -> String {
        // TODO: KMP should compute a unique identifier for each alarm
        return "\(Self.notificationIDPrefix)\(alarmContext.event.masterEventIdValue):\(alarmContext.alarm.hash())"
    }
}
