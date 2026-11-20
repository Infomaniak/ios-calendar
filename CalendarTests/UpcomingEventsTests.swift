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

@testable import CalendarCoreUI
import Foundation
import Testing

private func hour(_ hour: Double) -> Date {
    Date(timeIntervalSince1970: hour * 3600)
}

private func event(_ startHour: Double, _ endHour: Double, isAllDay: Bool = false) -> UIEventSummary {
    UIEventSummary(details: UIEventDetails(
        id: "\(startHour)-\(endHour)",
        occurrenceId: "\(startHour)-\(endHour)",
        title: "Event",
        startDate: hour(startHour),
        endDate: hour(endHour),
        isAllDay: isAllDay,
        status: .confirmed,
        calendarId: "0",
        accountId: 0,
        attendees: [],
        colors: .preview,
        timing: .preview,
        canEdit: true
    ))
}

struct UpcomingEventsTests {
    @Test func sortsAllDayEventsFirstThenByStartDate() {
        let allDay = event(0, 24, isAllDay: true)
        let events = [event(12, 13), allDay, event(8, 9)]
        #expect(events.sortedForPlanning() == [allDay, event(8, 9), event(12, 13)])
    }

    @Test func keepsOngoingAndUpcomingEvents() {
        let allDay = event(0, 24, isAllDay: true)
        let events = [allDay, event(8, 9), event(9.5, 11), event(12, 13)]
        #expect(events.upcoming(at: hour(10)) == [allDay, event(9.5, 11), event(12, 13)])
    }

    @Test func dropsEventEndingNow() {
        #expect([event(8, 10)].upcoming(at: hour(10)).isEmpty)
    }
}
