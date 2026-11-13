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

import CalendarCore
import Foundation
import Testing

struct EventMoveOffsetTests {
    private let calendar: Foundation.Calendar = {
        var calendar = Foundation.Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich") ?? .current
        return calendar
    }()

    @Test
    func movingByDaysKeepsTheWallClockTimeAcrossDaylightSavingTime() throws {
        // Daylight saving time starts on 29 March 2026 in Zurich.
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 10, minute: 30)))

        let moved = EventMoveOffset(days: 1, seconds: 45 * 60).apply(to: start, calendar: calendar)

        let components = calendar.dateComponents([.day, .hour, .minute], from: moved)
        #expect(components.day == 29)
        #expect(components.hour == 11)
        #expect(components.minute == 15)
    }

    @Test(arguments: [(28, 29), (29, 28), (29, 30)])
    func offsetBetweenSlicesLandsOnTheProposedStartAcrossDaylightSavingTime(fromDay: Int, toDay: Int) throws {
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: fromDay, hour: 10)))
        let proposedStart = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: toDay,
            hour: 14,
            minute: 15
        )))

        let offset = EventMoveOffset(from: start, to: proposedStart, calendar: calendar)

        #expect(offset.days == toDay - fromDay)
        #expect(offset.apply(to: start, calendar: calendar) == proposedStart)
    }

    @Test
    func invertedOffsetMovesBackToTheOriginalDate() throws {
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 16)))
        let offset = EventMoveOffset(days: -3, seconds: 90 * 60)

        let movedBack = offset.inverted.apply(to: offset.apply(to: start, calendar: calendar), calendar: calendar)

        #expect(movedBack == start)
    }
}
