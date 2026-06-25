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
import Collections
import Foundation
import InfomaniakDI
import MultiplatformCalendar
import UIKit

@MainActor
class PlanningViewModel: ObservableObject {
    nonisolated static let windowSize = 10
    nonisolated static let dayCount = 10000

    private var planningDays: OrderedDictionary<Date, PlanningDay> = [:]
    @Published var scrollTarget: Date?
    @Published var lastDifference: PlanningViewDifference?

    private var currentObserveTask: Task<Void, Never>?

    private let referenceDate: Date

    nonisolated var totalDays: Int {
        // Past - Current Date - Future
        Self.dayCount + 1 + Self.dayCount
    }

    init() {
        referenceDate = Calendar.current.startOfDay(for: Date())
        guard let startDate = Calendar.current.date(byAdding: .day, value: -Self.windowSize, to: referenceDate),
              let endDate = Calendar.current.date(byAdding: .day, value: Self.windowSize, to: referenceDate) else {
            return
        }
        observeEventsForWindow(startDate: startDate, endDate: endDate)
    }

    private func observeEventsForWindow(startDate: Date, endDate: Date) {
        currentObserveTask?.cancel()
        currentObserveTask = Task.detached { [weak self] in
            @InjectService var calendarSDK: CalendarCoreGraph
            for await events in calendarSDK.calendarManager.observeEvents(start: startDate.instant, end: endDate.instant) {
                guard let self else { return }

                var newPlanningDays: OrderedDictionary<Date, PlanningDay> = [:]
                let uiEvents = events.compactMap { UIEvent(event: $0, userEmail: "") }

                let calendar = Calendar.current
                let eventsByDay = Dictionary(grouping: uiEvents) { event in
                    calendar.startOfDay(for: event.startDate)
                }

                for (dayDate, events) in eventsByDay {
                    let sortedEvents = events.sorted { $0.startDate < $1.startDate }
                    newPlanningDays[dayDate] = PlanningDay(date: dayDate, events: sortedEvents)
                }

                let oldPlanningDays = await planningDays
                let difference = await computeDifference(from: oldPlanningDays, to: newPlanningDays)
                await MainActor.run {
                    self.planningDays = newPlanningDays
                    self.lastDifference = difference
                }
            }
        }
    }

    nonisolated func sectionIndex(for date: Date) -> Int {
        let firstIndexPathDate = getPlanningDateAtIndex(0)

        return Calendar.current.dateComponents([.day], from: firstIndexPathDate, to: date).day ?? 0
    }

    nonisolated func getPlanningDateAtIndex(_ index: Int) -> Date {
        let dayOffset = index - Self.dayCount
        guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: referenceDate) else {
            fatalError("Failed to calculate date for index \(index)")
        }

        return date
    }

    func numberOfItemsInSection(index section: Int) -> Int {
        let day = getPlanningDayAtIndex(section)
        guard !day.events.isEmpty else {
            return day.isWeekStart ? 1 : 0
        }
        let weekHeaderCount = day.isWeekStart ? 1 : 0
        return day.events.count + weekHeaderCount
    }

    func getPlanningDayAtIndex(_ index: Int) -> PlanningDay {
        let date = getPlanningDateAtIndex(index)

        if let planningDay = planningDays[date] {
            return planningDay
        }

        return PlanningDay(date: date, events: [])
    }

    @concurrent
    private func computeDifference(
        from oldPlanningDays: OrderedDictionary<Date, PlanningDay>,
        to newPlanningDays: OrderedDictionary<Date, PlanningDay>
    ) async -> PlanningViewDifference {
        var added: [IndexPath] = []
        var updated: [IndexPath] = []
        var removed: [IndexPath] = []

        let firstIndexPathDate = getPlanningDateAtIndex(0)
        let lastIndexPathDate = getPlanningDateAtIndex(totalDays - 1)

        for (date, newDay) in newPlanningDays {
            guard date >= firstIndexPathDate,
                  date <= lastIndexPathDate else {
                continue
            }

            let sectionIndex = sectionIndex(for: date)

            // Item 0 is reserved for the week header on week-start days, so event indexes are shifted.
            let itemOffset = newDay.isWeekStart ? 1 : 0

            guard let oldDay = oldPlanningDays[date] else {
                for eventIndex in newDay.events.indices {
                    added.append(IndexPath(item: eventIndex + itemOffset, section: sectionIndex))
                }
                continue
            }

            guard oldDay != newDay else {
                continue
            }

            for (eventIndex, newEvent) in newDay.events.enumerated() {
                let indexPath = IndexPath(item: eventIndex + itemOffset, section: sectionIndex)
                if oldDay.events.count < eventIndex + itemOffset {
                    let oldEvent = oldDay.events[eventIndex + itemOffset]
                    if oldEvent != newEvent {
                        updated.append(indexPath)
                    }
                } else {
                    added.append(indexPath)
                }
            }

            for (eventIndex, oldEvent) in oldDay.events.enumerated()
                where !newDay.events.contains(where: { $0.id == oldEvent.id }) {
                removed.append(IndexPath(item: eventIndex + itemOffset, section: sectionIndex))
            }
        }

        return PlanningViewDifference(added: added, updated: updated, removed: removed)
    }
}
