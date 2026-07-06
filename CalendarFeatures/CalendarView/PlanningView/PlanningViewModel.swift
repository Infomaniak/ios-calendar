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
import InfomaniakDI
import MultiplatformCalendar

@MainActor @Observable
class PlanningViewModel {
    /// Number of weeks kept resident in the collection view at any moment.
    nonisolated static let windowWeeks = 8
    /// Number of days added/removed each time the window recycles.
    nonisolated static let shiftDays = 7
    /// Extra days observed on each side of the window so events are ready before the user scrolls them into view.
    nonisolated static let observeBufferDays = 7

    nonisolated static var windowDays: Int {
        windowWeeks * 7
    }

    private(set) var days: [PlanningDay] = []
    var scrollTarget: Date?

    private let calendar = Calendar.current
    @ObservationIgnored private var eventsByDay: [Date: [CalendarCoreUI.UIEvent]] = [:]
    @ObservationIgnored private var anchorDate: Date
    @ObservationIgnored private var currentObserveTask: Task<Void, Never>?

    init() {
        let today = Calendar.current.startOfDay(for: Date())
        anchorDate = Self.centeredAnchor(for: today, calendar: Calendar.current)
        rebuildDays()
        observeEvents()
    }

    func sectionIndex(for date: Date) -> Int? {
        let day = calendar.startOfDay(for: date)
        return days.firstIndex { $0.date == day }
    }

    func shiftForward() {
        shiftWindow(byDays: Self.shiftDays)
    }

    func shiftBackward() {
        shiftWindow(byDays: -Self.shiftDays)
    }

    func reAnchor(around date: Date) {
        anchorDate = Self.centeredAnchor(for: date, calendar: calendar)
        rebuildDays()
        observeEvents()
    }

    private func shiftWindow(byDays dayOffset: Int) {
        guard let newAnchor = calendar.date(byAdding: .day, value: dayOffset, to: anchorDate) else { return }
        anchorDate = newAnchor
        rebuildDays()
        observeEvents()
    }

    private func rebuildDays() {
        days = PlanningDay.makeWindow(
            startDate: anchorDate,
            dayCount: Self.windowDays,
            eventsByDay: eventsByDay,
            calendar: calendar
        )
    }

    private func observeEvents() {
        guard let start = calendar.date(byAdding: .day, value: -Self.observeBufferDays, to: anchorDate),
              let end = calendar.date(byAdding: .day, value: Self.windowDays + Self.observeBufferDays, to: anchorDate)
        else {
            return
        }

        currentObserveTask?.cancel()
        currentObserveTask = Task.detached { [weak self] in
            @InjectService var calendarSDK: CalendarCoreGraph
            for await events in calendarSDK.calendarManager.observeEvents(start: start.instant, end: end.instant) {
                guard let self else { return }
                let uiEvents = events.compactMap { CalendarCoreUI.UIEvent(event: $0, userEmail: "") }
                await ingest(uiEvents: uiEvents)
            }
        }
    }

    @concurrent
    private func ingest(uiEvents: [CalendarCoreUI.UIEvent]) async {
        let groupedEvents = Dictionary(grouping: uiEvents) { calendar.startOfDay(for: $0.startDate) }
        let newDays = await PlanningDay.makeWindow(
            startDate: anchorDate,
            dayCount: Self.windowDays,
            eventsByDay: groupedEvents,
            calendar: calendar
        )
        await MainActor.run {
            eventsByDay = groupedEvents
            days = newDays
        }
    }

    private static func centeredAnchor(for date: Date, calendar: Foundation.Calendar) -> Date {
        let weekStart = calendar.weekStart(for: date)
        let weeksBefore = windowWeeks / 2
        return calendar.date(byAdding: .day, value: -weeksBefore * 7, to: weekStart) ?? weekStart
    }
}
