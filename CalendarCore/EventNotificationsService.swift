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
import UserNotifications

final class EventNotificationsService: Sendable {
    let referenceDate: Date
    let windowSize: TimeInterval

    init(referenceDate: Date = .now, windowSize: TimeInterval) {
        self.referenceDate = referenceDate
        self.windowSize = windowSize
    }

    func handleEventsNotifications() async {
        let rangeOfEvents = referenceDate ..< referenceDate.addingTimeInterval(windowSize)
        let eventsWithNotifications = await eventsWithNotifications(rangeOfEvents)

        let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()

        let diff = diffEventsAndNotifications(events: eventsWithNotifications, pendingNotifications: pendingNotifications)
        await unscheduleStaleNotifications(diff.toUnschedule)
        await scheduleNotificationsForEvents(diff.toSchedule)
    }

    private func eventsWithNotifications(_ range: Range<Date>) async -> [Event] {
        // TODO: Waiting for the KMP implementation
        return []
    }

    private func diffEventsAndNotifications(
        events: [Event], pendingNotifications: [UNNotificationRequest]
    ) -> (toSchedule: [EventDaySlice], toUnschedule: [UNNotificationRequest]) {
        return ([], [])
    }

    private func unscheduleStaleNotifications(_ notifications: [UNNotificationRequest]) async {
        let identifiers = notifications.map { $0.identifier }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func scheduleNotificationsForEvents(_ events: [Event]) async {
        for event in events {
            for alarm in event.alarms {
                guard let request = generateNotificationRequestForAlarm(alarm, event: event) else { continue }
                try? await UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func generateNotificationRequestForAlarm(_ alarm: EventAlarm, event: Event) -> UNNotificationRequest? {
        let content = UNMutableNotificationContent()
        content.title = event.title

        let trigger: UNCalendarNotificationTrigger
        if let absoluteTrigger = alarm.trigger as? AlarmTriggerAbsolute {

        } else if let relativeTrigger = alarm.trigger as? AlarmTriggerRelative {

        } else {
            return nil
        }

        let id = notificationID(for: event, alarm: alarm)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    private func notificationID(for event: Event, alarm: EventAlarm) -> String {
        // TODO: Generate unique ID for a notification based on event and alarm
        return "WIP"
    }
}
