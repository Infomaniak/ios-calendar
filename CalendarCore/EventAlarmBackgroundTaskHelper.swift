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

import BackgroundTasks
import InfomaniakDI
import MultiplatformCalendar
import OSLog

public struct EventAlarmBackgroundTaskHelper {
    public static let identifier = "com.infomaniak.calendar.refresh-event-alarms"

    public init() {}

    public func scheduleIfNecessary() async {
        @LazyInjectService var accountManager: AccountManager
        guard await !accountManager.calendarAccounts.isEmpty else {
            return
        }

        schedule()
    }

    public func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: EventAlarmBackgroundTaskHelper.identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.general.error("Could not schedule refresh-event-alarms: \(error)")
        }
    }
}
