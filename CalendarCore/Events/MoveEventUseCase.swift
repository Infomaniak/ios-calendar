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
import InfomaniakDI
import MultiplatformCalendar

/// How far an event is moved: whole days first (keeping the wall-clock time across DST), then a time offset.
public struct EventMoveOffset: Equatable, Hashable, Sendable {
    public let days: Int
    public let seconds: TimeInterval

    public var isZero: Bool {
        return days == 0 && seconds == 0
    }

    public var inverted: EventMoveOffset {
        return EventMoveOffset(days: -days, seconds: -seconds)
    }

    public init(days: Int = 0, seconds: TimeInterval = 0) {
        self.days = days
        self.seconds = seconds
    }

    /// The offset moving `start` to `newStart`, measured from the day-shifted start so that it is exact across DST.
    public init(from start: Date, to newStart: Date, calendar: Foundation.Calendar) {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: newStart)
        ).day ?? 0
        let shiftedStart = calendar.date(byAdding: .day, value: days, to: start) ?? start
        self.init(days: days, seconds: newStart.timeIntervalSince(shiftedStart))
    }

    public func apply(to date: Date, calendar: Foundation.Calendar) -> Date {
        let shiftedDay = calendar.date(byAdding: .day, value: days, to: date) ?? date
        return shiftedDay.addingTimeInterval(seconds)
    }
}

public struct MoveEventUseCase: Sendable {
    public init() {}

    public func execute(
        occurrenceId: String,
        offset: EventMoveOffset,
        scope: RecurrenceScope,
        calendar: Foundation.Calendar = .current
    ) async throws {
        guard !offset.isZero else { return }

        @InjectService var calendarSDK: CalendarCoreGraph
        let id = OccurrenceId.companion.parse(value: occurrenceId)
        guard let occurrence = try await calendarSDK.calendarManager.getOccurrence(occurrenceId: id),
              let editData = try await calendarSDK.calendarManager.getEditData(occurrenceId: id) else {
            throw CalendarError.eventOccurrenceNotFound
        }

        var draft = EventDraft(event: occurrence, editData: editData)
        draft.startDate = offset.apply(to: draft.startDate, calendar: calendar)
        draft.endDate = offset.apply(to: draft.endDate, calendar: calendar)

        let target = occurrence.targetFor(scope: scope)
        try await calendarSDK.calendarManager.updateEvent(
            target: target,
            data: draft.toEventEditData(preserving: editData)
        )
    }
}
