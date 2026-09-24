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

@testable import CalendarCalendarView
import Foundation
import Testing

struct CalendarPeriodCollectionTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    @Test func randomAccessAndSlices() throws {
        let origin = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31)))
        let periods = CalendarPeriodCollection(calendar: calendar, component: .month, origin: origin, indices: -1200 ..< 1201)

        #expect(periods.count == 2401)
        #expect(periods.indices == -1200 ..< 1201)
        #expect(periods.index(periods.startIndex, offsetBy: 1200) == 0)
        #expect(periods.distance(from: 1200, to: -1200) == -2400)
        #expect(periods.index(after: -1) == 0)
        #expect(periods.index(before: 1) == 0)
        #expect(periods[-2 ..< 2].map(\.id) == [-2, -1, 0, 1])
        #expect(periods[0].date == calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))
        #expect(periods[1].date == calendar.date(from: DateComponents(year: 2026, month: 2, day: 1)))
    }

    @Test(arguments: [Calendar.Component.day, .weekOfYear, .month])
    func periodOffsetsRoundTrip(component: Calendar.Component) throws {
        let origin = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31)))
        let periods = CalendarPeriodCollection(calendar: calendar, component: component, origin: origin, indices: -1200 ..< 1201)

        for index in [-1200, -24, -1, 0, 1, 24, 1200] {
            #expect(periods[index].id == index)
            #expect(periods.index(for: periods[index].date) == index)
            #expect(periods[index].date == calendar.date(byAdding: component, value: index, to: periods.origin))
        }

        let beforeRange = try #require(calendar.date(byAdding: component, value: -1201, to: periods.origin))
        let afterRange = try #require(calendar.date(byAdding: component, value: 1201, to: periods.origin))
        #expect(periods.index(for: beforeRange) == nil)
        #expect(periods.index(for: afterRange) == nil)
        #expect(periods.index(for: origin) == 0)
        #expect(periods.count == 2401)
    }

    @Test func daysRespectDaylightSavingTime() throws {
        let origin = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 12)))
        let periods = CalendarPeriodCollection(calendar: calendar, component: .day, origin: origin, indices: -2 ..< 3)

        #expect(periods[2].date.timeIntervalSince(periods[1].date) == 23 * 60 * 60)
        #expect(calendar.component(.hour, from: periods[2].date) == 0)
        #expect(calendar.component(.day, from: periods[2].date) == 30)
    }

    @Test func monthsRespectNonGregorianCalendars() throws {
        let origin = try #require(calendar.date(from: DateComponents(year: 2024, month: 3, day: 1)))
        let hebrewCalendar = Calendar(identifier: .hebrew)
        let periods = CalendarPeriodCollection(calendar: hebrewCalendar, component: .month, origin: origin, indices: -12 ..< 13)

        for index in periods.indices {
            #expect(periods.index(for: periods[index].date) == index)
            #expect(hebrewCalendar.component(.day, from: periods[index].date) == 1)
        }
    }
}
