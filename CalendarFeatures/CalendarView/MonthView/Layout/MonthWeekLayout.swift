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

    /// - Parameters:
    ///   - laneCount: Lanes displayed in a column without hidden events.
    ///   - truncatedLaneCount: Lanes displayed above the hidden events indicator in a column with hidden events.
    func visibleSegments(laneCount: Int, truncatedLaneCount: Int) -> [MonthEventSegment] {
        let overflowingColumns = overflowingColumns(laneCount: laneCount, truncatedLaneCount: truncatedLaneCount)
        return segments.filter {
            isVisible($0, laneCount: laneCount, truncatedLaneCount: truncatedLaneCount, overflowingColumns: overflowingColumns)
        }
    }

    func columnsWithHiddenEvents(laneCount: Int, truncatedLaneCount: Int) -> [Bool] {
        let overflowingColumns = overflowingColumns(laneCount: laneCount, truncatedLaneCount: truncatedLaneCount)
        return dayEvents.indices.map { overflowingColumns.contains($0) }
    }

    private func overflowingColumns(laneCount: Int, truncatedLaneCount: Int) -> Set<Int> {
        let truncatedLaneCount = min(truncatedLaneCount, laneCount)
        var overflowingColumns = Set<Int>()
        for segment in segments where segment.lane >= laneCount {
            overflowingColumns.formUnion(segment.columns)
        }

        // Hiding a multi-day segment marks all its columns as overflowing, which can hide more segments.
        var didChange = true
        while didChange {
            didChange = false
            for segment in segments
                where !isVisible(segment, laneCount: laneCount, truncatedLaneCount: truncatedLaneCount,
                                 overflowingColumns: overflowingColumns)
                && !overflowingColumns.isSuperset(of: segment.columns) {
                overflowingColumns.formUnion(segment.columns)
                didChange = true
            }
        }

        return overflowingColumns
    }

    private func isVisible(
        _ segment: MonthEventSegment,
        laneCount: Int,
        truncatedLaneCount: Int,
        overflowingColumns: Set<Int>
    ) -> Bool {
        if segment.lane < min(truncatedLaneCount, laneCount) {
            return true
        }
        return segment.lane < laneCount && !segment.columns.contains { overflowingColumns.contains($0) }
    }
}

extension MonthWeekLayout {
    static func layouts(for grid: MonthGrid, eventsByDay: [Date: [UIEventSummary]]) -> [MonthWeekLayout] {
        return grid.weeks.map { days in
            MonthWeekLayout(days: days, eventsByDay: eventsByDay, isDisplayed: grid.isInMonth)
        }
    }
}
