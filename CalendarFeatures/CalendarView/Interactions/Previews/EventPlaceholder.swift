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
import CalendarResources
import Foundation
import MultiplatformCalendar

struct EventPlaceholder: Equatable, EventCellStylable {
    enum Kind: Equatable {
        case creation
        case move(occurrenceId: String)
    }

    let kind: Kind

    let title: String
    let colors: UIEventColor
    let status: EventStatus?
    let myStatus: UIParticipationStatus?
    let isAllDay: Bool
    var start: Date
    var end: Date

    var duration: TimeInterval {
        return end.timeIntervalSince(start)
    }

    init(creationWithColors colors: UIEventColor, isAllDay: Bool, start: Date, end: Date) {
        kind = .creation
        title = CalendarResourcesStrings.newEventTitle
        self.colors = colors
        self.isAllDay = isAllDay
        self.start = start
        self.end = end
        status = nil
        myStatus = nil
    }

    init(moving event: UIEventSummary, to start: Date) {
        kind = .move(occurrenceId: event.occurrenceId)
        title = event.title
        colors = event.colors
        status = event.status
        myStatus = event.myStatus
        isAllDay = event.isAllDay
        self.start = start
        end = start.addingTimeInterval(event.endDate.timeIntervalSince(event.startDate))
    }

    mutating func move(to newStart: Date) {
        end = newStart.addingTimeInterval(duration)
        start = newStart
    }
}
