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
import InfomaniakCore
import InfomaniakDI
@preconcurrency import MultiplatformCalendar
import OSLog

public actor CalendarSyncHelper: ExpiringActivityDelegate {
    private static let logger = Logger(category: "CalendarSyncHelper")

    private var currentSyncTask: Task<Void, Never>?

    public init() {}

    public func syncCalendars() {
        let previousTask = currentSyncTask
        previousTask?.cancel()

        currentSyncTask = Task {
            await previousTask?.value
            guard !Task.isCancelled else { return }

            Self.logger.debug("Calendar sync started")
            let activity = ExpiringActivity(delegate: self)
            activity.start()

            @InjectService var calendarSDK: CalendarCoreGraph

            do {
                try await calendarSDK.calendarManager.syncEvents()
            } catch is CancellationError {
                Self.logger.info("Calendar sync cancelled")
            } catch {
                Self.logger.error("Failed to sync calendars: \(error.localizedDescription)")
            }

            activity.endAll()
            Self.logger.debug("Calendar done \(Task.isCancelled ? "- Cancelled" : "")")
        }
    }

    public nonisolated func backgroundActivityExpiring() {
        Task {
            await currentSyncTask?.cancel()
        }
    }
}
