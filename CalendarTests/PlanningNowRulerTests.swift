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
        attendees: [],
        colors: .preview,
        timing: .preview,
        canEdit: true
    ))
}

struct PlanningNowRulerTests {
    private let allDay = event(0, 24, isAllDay: true)

    @Test func noEvents() {
        #expect(PlanningNowRuler.insertionIndex(in: [], now: hour(10)) == nil)
    }

    @Test func onlyAllDayEvents() {
        #expect(PlanningNowRuler.insertionIndex(in: [allDay], now: hour(10)) == nil)
    }

    @Test func beforeOngoingEvent() {
        let events = [allDay, event(8, 9), event(9.5, 11), event(12, 13)]
        #expect(PlanningNowRuler.insertionIndex(in: events, now: hour(10)) == 2)
    }

    @Test func beforeMostRecentlyStartedOngoingEvent() {
        let events = [event(8, 17), event(9, 12), event(9.5, 10), event(14, 15)]
        #expect(PlanningNowRuler.insertionIndex(in: events, now: hour(10.5)) == 1)
    }

    @Test func ongoingEventStartingNow() {
        let events = [event(8, 9), event(10, 11)]
        #expect(PlanningNowRuler.insertionIndex(in: events, now: hour(10)) == 1)
    }

    @Test func beforeNextUpcomingEvent() {
        let events = [allDay, event(8, 9), event(12, 13), event(14, 15)]
        #expect(PlanningNowRuler.insertionIndex(in: events, now: hour(10)) == 2)
    }

    @Test func eventEndingNowIsNotOngoing() {
        let events = [event(8, 10), event(12, 13)]
        #expect(PlanningNowRuler.insertionIndex(in: events, now: hour(10)) == 1)
    }

    @Test func beforeFirstEventWhenAllUpcoming() {
        let events = [allDay, event(12, 13)]
        #expect(PlanningNowRuler.insertionIndex(in: events, now: hour(10)) == 1)
    }

    @Test func afterLastEventWhenAllOver() {
        let events = [allDay, event(8, 9), event(9, 10)]
        #expect(PlanningNowRuler.insertionIndex(in: events, now: hour(18)) == 3)
    }
}
