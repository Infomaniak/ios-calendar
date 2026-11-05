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

import CalendarCoreUI
import Foundation

enum PlanningNowRuler {
    static func insertionIndex(in events: [UIEventSummary], now: Date) -> Int? {
        let timedIndices = events.indices.filter { !events[$0].isAllDay }
        guard let lastTimedIndex = timedIndices.last else { return nil }

        let ongoingIndex = timedIndices
            .filter { events[$0].startDate <= now && now < events[$0].endDate }
            .max { events[$0].startDate < events[$1].startDate }
        if let ongoingIndex {
            return ongoingIndex
        }

        if let upcomingIndex = timedIndices.first(where: { events[$0].startDate > now }) {
            return upcomingIndex
        }

        return lastTimedIndex + 1
    }
}
