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

struct MonthEventSegment: Identifiable, Equatable {
    let id: String
    let event: UIEventSummary
    let startColumn: Int
    let span: Int
    let lane: Int

    var columns: Range<Int> {
        startColumn ..< startColumn + span
    }
}

private struct PendingSegment {
    let event: UIEventSummary
    let startColumn: Int
    let order: Int
    var span = 1
}

struct MonthWeekLayout: Equatable {
    let segments: [MonthEventSegment]
    let dayEvents: [[UIEventSummary]]

    init(days: [Date], eventsByDay: [Date: [UIEventSummary]], isDisplayed: (Date) -> Bool) {
        let columnEvents = days.map { isDisplayed($0) ? eventsByDay[$0] ?? [] : [] }

        var pendingSegments = [PendingSegment]()
        var openSegmentIndexByOccurrence = [String: Int]()
        for (column, events) in columnEvents.enumerated() {
            var nextOpenSegmentIndexByOccurrence = [String: Int]()
            for event in events {
                let occurrenceId = event.occurrenceId
                if let index = openSegmentIndexByOccurrence[occurrenceId] {
                    pendingSegments[index].span += 1
                    nextOpenSegmentIndexByOccurrence[occurrenceId] = index
                } else {
                    pendingSegments.append(PendingSegment(event: event, startColumn: column, order: pendingSegments.count))
                    nextOpenSegmentIndexByOccurrence[occurrenceId] = pendingSegments.count - 1
                }
            }
            openSegmentIndexByOccurrence = nextOpenSegmentIndexByOccurrence
        }

        let sortedSegments = pendingSegments.sorted { lhs, rhs in
            let lhsIsMultiDay = lhs.span > 1
            let rhsIsMultiDay = rhs.span > 1
            if lhsIsMultiDay != rhsIsMultiDay {
                return lhsIsMultiDay
            }

            if lhsIsMultiDay {
                if lhs.startColumn != rhs.startColumn {
                    return lhs.startColumn < rhs.startColumn
                }
                if lhs.span != rhs.span {
                    return lhs.span > rhs.span
                }
            }

            return lhs.order < rhs.order
        }

        var occupiedLanes = Array(repeating: Set<Int>(), count: days.count)
        segments = sortedSegments.map { pendingSegment in
            let columns = pendingSegment.startColumn ..< pendingSegment.startColumn + pendingSegment.span

            var lane = 0
            while columns.contains(where: { occupiedLanes[$0].contains(lane) }) {
                lane += 1
            }

            for column in columns {
                occupiedLanes[column].insert(lane)
            }

            return MonthEventSegment(
                id: "\(pendingSegment.startColumn)-\(pendingSegment.event.occurrenceId)",
                event: pendingSegment.event,
                startColumn: pendingSegment.startColumn,
                span: pendingSegment.span,
                lane: lane
            )
        }

        dayEvents = columnEvents
    }

    func visibleSegments(laneCount: Int) -> [MonthEventSegment] {
        let overflowingColumns = overflowingColumns(laneCount: laneCount)
        return segments.filter { isVisible($0, laneCount: laneCount, overflowingColumns: overflowingColumns) }
    }

    func columnsWithHiddenEvents(laneCount: Int) -> [Bool] {
        let overflowingColumns = overflowingColumns(laneCount: laneCount)
        var hasHiddenEvents = Array(repeating: false, count: dayEvents.count)
        for segment in segments where !isVisible(segment, laneCount: laneCount, overflowingColumns: overflowingColumns) {
            for column in segment.columns {
                hasHiddenEvents[column] = true
            }
        }

        return hasHiddenEvents
    }

    private func overflowingColumns(laneCount: Int) -> Set<Int> {
        var usedLaneCounts = Array(repeating: 0, count: dayEvents.count)
        for segment in segments {
            for column in segment.columns {
                usedLaneCounts[column] = max(usedLaneCounts[column], segment.lane + 1)
            }
        }

        return Set(usedLaneCounts.indices.filter { usedLaneCounts[$0] > laneCount })
    }

    private func isVisible(_ segment: MonthEventSegment, laneCount: Int, overflowingColumns: Set<Int>) -> Bool {
        if segment.lane < laneCount - 1 {
            return true
        }
        return segment.lane == laneCount - 1 && !segment.columns.contains { overflowingColumns.contains($0) }
    }
}

extension MonthWeekLayout {
    static func layouts(for grid: MonthGrid, eventsByDay: [Date: [UIEventSummary]]) -> [MonthWeekLayout] {
        return grid.weeks.map { days in
            MonthWeekLayout(days: days, eventsByDay: eventsByDay, isDisplayed: grid.isInMonth)
        }
    }
}
