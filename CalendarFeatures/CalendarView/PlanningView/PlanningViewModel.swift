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
    static let windowSize = 500
    static let dayCount = 10_000

    @Published private var planningDays: OrderedDictionary<Date, PlanningDay> = [:]
    @Published var scrollTarget: Date?

    private var currentObserveTask: Task<Void, Never>?

    private let referenceDate: Date

    var totalDays: Int {
        // Past - Current Date - Future
        Self.dayCount + 1 + Self.dayCount
    }

    init() {
        referenceDate = Calendar.current.startOfDay(for: Date())
        //observeEventsForWindow(startDate: startDate, endDate: endDate)
    }

    private func observeEventsForWindow(startDate: Date, endDate: Date) {
        currentObserveTask?.cancel()
        currentObserveTask = Task.detached { [weak self] in
            @InjectService var calendarSDK: CalendarCoreGraph
            for await events in calendarSDK.calendarManager.observeEvents(start: startDate.instant, end: endDate.instant) {
                guard var planningDays = await self?.planningDays else { return }
                let uiEvents = events.compactMap { UIEvent(event: $0, userEmail: "") }

                let calendar = Calendar.current
                let eventsByDay = Dictionary(grouping: uiEvents) { event in
                    calendar.startOfDay(for: event.startDate)
                }

                for (dayDate, events) in eventsByDay {
                    planningDays[dayDate] = PlanningDay(date: dayDate, events: events)
                }

                Task { @MainActor in
                    self?.planningDays = planningDays
                }
            }
        }
    }

    func getPlanningDayAtIndex(_ index: Int) -> PlanningDay {
        let dayOffset = index - Self.dayCount
        guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: referenceDate) else {
            fatalError("Failed to calculate date for index \(index)")
        }

        return PlanningDay(date: date, events: [])
    }
}
