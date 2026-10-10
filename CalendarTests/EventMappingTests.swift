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
import MultiplatformCalendar
import Testing

struct EventMappingTests {
    @Test func mapsSummaryParticipationAndSliceBounds() {
        let summary = makeSummary()
        let slice = EventDaySlice(
            event: summary,
            date: start.date,
            displayStart: start,
            displayEnd: end,
            position: DaySpanPosition(index: 1, count: 2)
        )
        let mapped = UIEventSummary(eventDaySlice: slice)

        #expect(mapped.id == "1-\(summary.occurrenceIdValue)")
        #expect(mapped.occurrenceId == summary.occurrenceIdValue)
        #expect(mapped.title == "Meeting")
        #expect(mapped.hasAttendees)
        #expect(!mapped.hasMeetRoom)
        #expect(mapped.myStatus == .delegated)
        #expect(mapped.startDate == slice.displayStartInstant().toNSDate())
        #expect(mapped.endDate == slice.displayEndInstant().toNSDate())
        #expect(mapped.isAllDay == slice.isAllDay)
    }

    @Test func mapsSummaryWithoutDaySlice() {
        let summary = makeSummary()
        let mapped = UIEventSummary(event: summary)

        #expect(mapped.id == summary.occurrenceIdValue)
        #expect(mapped.startDate == summary.timing.startInstantLocal().toNSDate())
        #expect(mapped.endDate == summary.timing.endInstantLocal().toNSDate())
        #expect(mapped.location == "Meeting room")
    }

    @Test func mapsFullEventAndResolvedContacts() throws {
        let contact = Contact(
            email: "guest@example.com",
            name: "Guest",
            avatar: ContactAvatarRemote(url: "https://example.com/avatar", accountId: 42),
            comesFromApi: true
        )
        let attendee = Attendee(
            email: "guest@example.com",
            displayName: "Guest",
            status: .accepted,
            role: .requested,
            isOrganizer: true,
            responseNeeded: false,
            type: .individual,
            contact: contact
        )
        let event = MultiplatformCalendar.Event(
            masterEventId: "event",
            occurrenceId: OccurrenceId.Master(masterId: "event"),
            calendarId: "calendar",
            accountId: 42,
            title: " Meeting ",
            description: "Full description",
            location: "Meeting room",
            status: .confirmed,
            timeBlocking: .blocks,
            classification: ClassificationPrivate(),
            categories: [],
            meetRoomUrl: "https://kmeet.infomaniak.com/meeting",
            bookableUuid: nil,
            attachments: [],
            timing: floatingTiming,
            lastModified: nil,
            attendees: [attendee],
            organizer: Organizer(email: attendee.email, displayName: "Guest", contact: contact),
            colors: colors,
            canEdit: true,
            alarms: []
        )
        let mapped = UIEventDetails(event: event, userEmail: " GUEST@EXAMPLE.COM ")

        #expect(mapped.id == event.occurrenceIdValue)
        #expect(mapped.calendarId == "calendar")
        #expect(mapped.title == "Meeting")
        #expect(mapped.description == "Full description")
        #expect(mapped.kMeetLink?.absoluteString == event.meetRoomUrl)
        #expect(mapped.classification == .private)
        #expect(mapped.canEdit)
        #expect(mapped.user?.status == .accepted)
        let mappedContact = try #require(mapped.attendees.first?.contact)
        #expect(mappedContact.name == "Guest")
        #expect(mappedContact.avatar == .remote(url: "https://example.com/avatar", accountId: 42))
        #expect(mapped.organizer?.contact == mappedContact)
    }

    @Test func mapsAttendeeWithoutContact() {
        let attendee = Attendee(
            email: "guest@example.com",
            displayName: nil,
            status: .needsAction,
            role: .requested,
            isOrganizer: false,
            responseNeeded: true
        )
        #expect(UIAttendee(attendee: attendee).contact == nil)
    }

    @Test func mapsUnanchoredTimingWithoutTimeZones() {
        let floating = UITiming(eventTiming: floatingTiming)
        #expect(floating.startTimeZone == nil)
        #expect(floating.endTimeZone == nil)
        #expect(floating.start == floatingTiming.startInstantLocal().toNSDate())

        let allDayTiming = EventTiming(
            bounds: EventBoundsAllDay(start: start.date, end: end.date),
            recurrenceRule: nil,
            rDates: [],
            exDates: []
        )
        let allDay = UITiming(eventTiming: allDayTiming)
        #expect(allDay.startTimeZone == nil)
        #expect(allDay.endTimeZone == nil)
        #expect(allDayTiming.isAllDay)
    }

    @Test func mapsZonedTimingWithSeparateTimeZones() {
        let timing = EventTiming(
            bounds: EventBoundsZoned(
                start: ZonedWallClock(
                    wallClock: start,
                    timeZone: MultiplatformCalendar.TimeZone.companion.of(zoneId: "Europe/Zurich")
                ),
                end: ZonedWallClock(
                    wallClock: end,
                    timeZone: MultiplatformCalendar.TimeZone.companion.of(zoneId: "Europe/London")
                )
            ),
            recurrenceRule: nil,
            rDates: [],
            exDates: []
        )
        let mapped = UITiming(eventTiming: timing)

        #expect(mapped.startTimeZone?.identifier == "Europe/Zurich")
        #expect(mapped.endTimeZone?.identifier == "Europe/London")
        #expect(mapped.start == timing.startInstantLocal().toNSDate())
        #expect(mapped.end == timing.endInstantLocal().toNSDate())
    }

    private func makeSummary() -> EventSummary {
        EventSummary(
            occurrenceId: OccurrenceId.Master(masterId: "event"),
            title: " Meeting ",
            location: "Meeting room",
            status: .confirmed,
            colors: colors,
            timing: floatingTiming,
            hasAttendees: true,
            myStatus: .delegated
        )
    }

    private var floatingTiming: EventTiming {
        EventTiming(bounds: EventBoundsFloating(start: start, end: end), recurrenceRule: nil, rDates: [], exDates: [])
    }

    private var start: LocalDateTime {
        LocalDateTime(year: 2027, month: 1, day: 15, hour: 10, minute: 0, second: 0, nanosecond: 0)
    }

    private var end: LocalDateTime {
        LocalDateTime(year: 2027, month: 1, day: 16, hour: 11, minute: 0, second: 0, nanosecond: 0)
    }

    private var colors: EventColors {
        let themedColor = ThemedColor(light: 0, dark: 0)
        return EventColors(
            calendarSourceColor: 0,
            sourceColor: 0,
            containerColor: 0,
            onContainerColor: themedColor,
            containerVariantColor: 0,
            onContainerVariantColor: themedColor
        )
    }
}
