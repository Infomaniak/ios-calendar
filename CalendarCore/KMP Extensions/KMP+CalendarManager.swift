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

public extension CalendarManager {
    private static let logger = Logger(category: "CalendarManager")

    func downloadEvents(in interval: DateInterval) async {
        do {
            try await downloadEventsByRange(start: interval.start.instant, end: interval.end.instant)
        } catch is CancellationError {
            Self.logger.info("Events range download cancelled")
        } catch {
            Self.logger.error("Failed to download events by range: \(error.localizedDescription)")
        }
    }
}
