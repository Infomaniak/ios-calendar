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

import DesignSystem
import ESDSFoundation
import SwiftUI

struct MonthWeekRowView: View {
    @Environment(\.calendar) private var calendar

    @Environment(\.esdsTheme) private var theme

    let days: [Date]
    let today: Date
    let layout: MonthWeekLayout?
    let metrics: MonthGridMetrics
    let rowHeight: CGFloat
    let showWeekNumber: Bool
    let monthInterval: DateInterval

    private var laneCount: Int {
        metrics.maxEventsCount(rowHeight: rowHeight)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if showWeekNumber, let firstDay = days.first {
                Text(calendar.component(.weekOfYear, from: firstDay), format: .number)
                    .lineLimit(1)
                    .font(.caption2)
                    .foregroundStyle(theme.color.contentTertiary)
                    .frame(width: metrics.weekNumberWidth, height: metrics.dayNumberHeight)
                    .padding(.top, value: .mini)
            }

            ZStack(alignment: .top) {
                HStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        MonthDayCellView(
                            day: day,
                            isInMonth: day >= monthInterval.start && day < monthInterval.end,
                            isToday: calendar.isDate(day, inSameDayAs: today),
                            dayNumberHeight: metrics.dayNumberHeight
                        )
                    }
                }

                if let layout, laneCount > 0 {
                    MonthWeekEventsLayout(
                        columnCount: days.count,
                        laneHeight: metrics.laneHeight,
                        laneSpacing: MonthGridMetrics.laneSpacing,
                        horizontalInset: IKPadding.micro / 2
                    ) {
                        ForEach(layout.visibleSegments(laneCount: laneCount)) { segment in
                            MonthEventButton(event: segment.event)
                                .monthEventPlacement(column: segment.startColumn, span: segment.span, lane: segment.lane)
                        }

                        let hiddenEventCounts = layout.hiddenEventCounts(laneCount: laneCount)
                        ForEach(hiddenEventCounts.indices, id: \.self) { column in
                            if hiddenEventCounts[column] > 0 {
                                MonthDayEventsPopoverButton(
                                    day: days[column],
                                    hiddenEventCount: hiddenEventCounts[column],
                                    events: layout.dayEvents[column]
                                )
                                .monthEventPlacement(column: column, lane: laneCount - 1)
                            }
                        }
                    }
                    .padding(.top, metrics.dayNumberHeight + MonthGridMetrics.laneSpacing)
                }
            }
        }
        .frame(height: rowHeight)
    }
}
