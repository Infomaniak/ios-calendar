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
import DifferenceKit
import Foundation
import InfomaniakDI
import MultiplatformCalendar

@MainActor
class PlanningViewModel: ObservableObject {
    /// Number of weeks kept resident in the collection view at any moment.
    nonisolated static let windowWeeks = 8
    /// Number of days added/removed each time the window recycles.
    nonisolated static let shiftDays = 7
    /// Extra days observed on each side of the window so events are ready before the
    /// user scrolls them into view.
    nonisolated static let observeBufferDays = 7

    nonisolated static var windowDays: Int {
        windowWeeks * 7
    }

    /// Current snapshot of the visible window, one section per day. The collection
    /// view diffs its own backing copy against this to animate changes.
    @Published private(set) var sections: PlanningViewDifference = []
    @Published var scrollTarget: Date?

    private let calendar = Calendar.current
    private var eventsByDay: [Date: [CalendarCoreUI.UIEvent]] = [:]
    private var days: [PlanningDay] = []
    private var anchorDate: Date
    private var currentObserveTask: Task<Void, Never>?

    init() {
        let today = Calendar.current.startOfDay(for: Date())
        anchorDate = Self.centeredAnchor(for: today, calendar: Calendar.current)
        rebuildSections()
        observeEvents()
    }

    // MARK: - Lookups

    /// Section index of `date` within the current window, or `nil` if it is not resident.
    func sectionIndex(for date: Date) -> Int? {
        let day = calendar.startOfDay(for: date)
        return days.firstIndex { $0.date == day }
    }

    func planningDay(atSection index: Int) -> PlanningDay? {
        days.indices.contains(index) ? days[index] : nil
    }

    // MARK: - Recycling

    /// Moves the window one step towards the future (drops the oldest week, appends a new one).
    func shiftForward() {
        shiftWindow(byDays: Self.shiftDays)
    }

    /// Moves the window one step towards the past (drops the newest week, prepends an older one).
    func shiftBackward() {
        shiftWindow(byDays: -Self.shiftDays)
    }

    /// Rebuilds the window centred on `date`. Used when jumping to a date outside the resident range.
    func reAnchor(around date: Date) {
        anchorDate = Self.centeredAnchor(for: date, calendar: calendar)
        rebuildSections()
        observeEvents()
    }

    private func shiftWindow(byDays dayOffset: Int) {
        guard let newAnchor = calendar.date(byAdding: .day, value: dayOffset, to: anchorDate) else { return }
        anchorDate = newAnchor
        rebuildSections()
        observeEvents()
    }

    // MARK: - Window building

    /// Week-aligned start date that keeps `date` roughly centred in the window.
    private static func centeredAnchor(for date: Date, calendar: Foundation.Calendar) -> Date {
        let weekStart = PlanningDay.weekStart(for: date, calendar: calendar)
        let weeksBefore = windowWeeks / 2
        return calendar.date(byAdding: .day, value: -weeksBefore * 7, to: weekStart) ?? weekStart
    }

    private func rebuildSections() {
        days = PlanningDay.makeWindow(
            startDate: anchorDate,
            dayCount: Self.windowDays,
            eventsByDay: eventsByDay,
            calendar: calendar
        )
        sections = days.map { ArraySection(model: $0, elements: $0.items) }
    }

    // MARK: - Observation

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
                await ingest(events: uiEvents)
            }
        }
    }

    private func ingest(events: [CalendarCoreUI.UIEvent]) {
        eventsByDay = Dictionary(grouping: events) { calendar.startOfDay(for: $0.startDate) }
        rebuildSections()
    }
}
