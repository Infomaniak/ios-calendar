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
    nonisolated static let baseWindowWeeks = 8
    nonisolated static let maxWindowWeeks = 54
    nonisolated static let growStepWeeks = 2
    nonisolated static let shiftDays = 7
    nonisolated static let observeBufferDays = 7

    private(set) var windowWeeks = baseWindowWeeks

    private var windowDays: Int {
        windowWeeks * 7
    }

    var canGrowWindow: Bool {
        windowWeeks + Self.growStepWeeks * 2 <= Self.maxWindowWeeks
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
        windowWeeks = Self.baseWindowWeeks
        anchorDate = Self.centeredAnchor(for: date, calendar: calendar)
        rebuildDays()
        observeEvents()
    }

    @discardableResult
    func growWindow() -> Bool {
        guard canGrowWindow,
              let newAnchor = calendar.date(byAdding: .day, value: -Self.growStepWeeks * 7, to: anchorDate) else {
            return false
        }
        windowWeeks += Self.growStepWeeks * 2
        anchorDate = newAnchor
        rebuildDays()
        observeEvents()
        return true
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
            dayCount: windowDays,
            eventsByDay: eventsByDay,
            calendar: calendar
        )
    }

    private func observeEvents() {
        guard let start = calendar.date(byAdding: .day, value: -Self.observeBufferDays, to: anchorDate),
              let end = calendar.date(byAdding: .day, value: windowDays + Self.observeBufferDays, to: anchorDate)
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
            dayCount: windowDays,
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
        let weeksBefore = baseWindowWeeks / 2
        return calendar.date(byAdding: .day, value: -weeksBefore * 7, to: weekStart) ?? weekStart
    }
}
