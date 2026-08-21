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

    private func eventsWithNotifications(_ range: Range<Date>) async -> [EventDaySlice] {
        // TODO: Add logic to fetch events from KMP once available
        return []
    }

    private func diffEventsAndNotifications(events: [EventDaySlice], pendingNotifications: [UNNotificationRequest]) -> (toSchedule: [EventDaySlice], toUnschedule: [UNNotificationRequest]) {
        return ([], [])
    }

    private func unscheduleStaleNotifications(_ notifications: [UNNotificationRequest]) async {

    }

    private func scheduleNotificationsForEvents(_ events: [EventDaySlice]) async {

    }
}
