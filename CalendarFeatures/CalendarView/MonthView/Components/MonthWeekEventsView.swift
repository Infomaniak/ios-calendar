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

import SwiftUI

struct MonthWeekEventsView: View {
    let segments: [MonthEventSegment]
    let hiddenEventCounts: [Int]
    let laneCount: Int
    let laneHeight: CGFloat

    var body: some View {
        MonthWeekEventsLayout(
            columnCount: hiddenEventCounts.count,
            laneHeight: laneHeight,
            laneSpacing: MonthGridMetrics.laneSpacing,
            horizontalInset: 4
        ) {
            ForEach(segments) { segment in
                MonthEventButton(event: segment.event)
                    .monthEventPlacement(column: segment.startColumn, span: segment.span, lane: segment.lane)
            }

            ForEach(hiddenEventCounts.indices, id: \.self) { column in
                if hiddenEventCounts[column] > 0 {
                    MonthDayHiddenEventsView(count: hiddenEventCounts[column])
                        .monthEventPlacement(column: column, lane: laneCount - 1)
                }
            }
        }
    }
}
