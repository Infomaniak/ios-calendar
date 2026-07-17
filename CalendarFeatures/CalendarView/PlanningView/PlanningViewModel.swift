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
import CalendarCoreUI
import Foundation
import InfomaniakDI
import MultiplatformCalendar

@MainActor @Observable
class PlanningViewModel {
    nonisolated static let daysBeforeToday = 10000
    nonisolated static let daysAfterToday = 10000
    nonisolated static let observeRadiusDays = 42
    nonisolated static let observeBufferDays = 7

    nonisolated static var sectionCount: Int {
        daysBeforeToday + daysAfterToday + 1
    }

    private(set) var days: [PlanningDay] = []
    private(set) var hasDeliveredEvents = false
    var scrollTarget: Date?
    var suppressScrollTargetSync = false

    private let calendar = Calendar.current
    @ObservationIgnored private let startDate: Date
    @ObservationIgnored private var eventsByDay: [Date: [CalendarCoreUI.UIEvent]] = [:]
    @ObservationIgnored private var observeCenterDate: Date
    @ObservationIgnored private var currentObserveTask: Task<Void, Never>?

    private let calendarAccounts: [CalendarAccount.ID: CalendarAccount]

    init(calendarAccounts: [CalendarAccount.ID: CalendarAccount]) {
        self.calendarAccounts = calendarAccounts

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        startDate = calendar.date(byAdding: .day, value: -Self.daysBeforeToday, to: today) ?? today
        observeCenterDate = today
        days = PlanningDay.makeWindow(
            startDate: startDate,
            dayCount: Self.sectionCount,
            eventsByDay: eventsByDay,
            calendar: calendar
        )
        observeEvents(around: today)
    }

    func sectionIndex(for date: Date) -> Int? {
        let day = calendar.startOfDay(for: date)
        guard let offset = calendar.dateComponents([.day], from: startDate, to: day).day,
              days.indices.contains(offset) else {
            return nil
        }
        return offset
    }

    func isWithinObserveWindow(_ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        guard let distance = calendar.dateComponents([.day], from: observeCenterDate, to: day).day else {
            return false
        }
        return abs(distance) <= Self.observeRadiusDays
    }

    func refreshObserveWindowIfNeeded(around date: Date) {
        let day = calendar.startOfDay(for: date)
        guard let distance = calendar.dateComponents([.day], from: observeCenterDate, to: day).day else {
            return
        }
        if abs(distance) > Self.observeRadiusDays - Self.observeBufferDays {
            observeEvents(around: day)
        }
    }

    func refreshObserveWindow(around date: Date) {
        observeEvents(around: calendar.startOfDay(for: date))
    }

    private func observeEvents(around center: Date) {
        observeCenterDate = center
        guard let start = calendar.date(byAdding: .day, value: -(Self.observeRadiusDays + Self.observeBufferDays), to: center),
              let end = calendar.date(byAdding: .day, value: Self.observeRadiusDays + Self.observeBufferDays, to: center)
        else {
            return
        }

        currentObserveTask?.cancel()
        currentObserveTask = Task.detached { [weak self] in
            @InjectService var calendarSDK: CalendarCoreGraph
            for await daySlices in calendarSDK.calendarManager.observeDaySlices(start: start.instant, end: end.instant) {
                guard let self else { return }
                let uiEvents = daySlices.values.flatMap { eventDaySlices in
                    eventDaySlices.compactMap {
                        let account = self.calendarAccounts[Int($0.event.accountIdValue)]
                        return CalendarCoreUI.UIEvent(eventDaySlice: $0, userEmail: account?.user.email ?? "")
                    }
                }
                await ingest(uiEvents: uiEvents)
            }
        }
    }

    @concurrent
    private func ingest(uiEvents: [CalendarCoreUI.UIEvent]) async {
        let groupedEvents = Dictionary(grouping: uiEvents) { calendar.startOfDay(for: $0.startDate) }
        let newDays = PlanningDay.makeWindow(
            startDate: startDate,
            dayCount: Self.sectionCount,
            eventsByDay: groupedEvents,
            calendar: calendar
        )
        await MainActor.run {
            eventsByDay = groupedEvents
            days = newDays
            hasDeliveredEvents = true
        }
    }
}
