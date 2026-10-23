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

struct MonthPageView: View {
    let grid: MonthGrid
    let weekLayouts: [MonthWeekLayout]?
    let metrics: MonthGridMetrics
    let today: Date
    let showWeekNumbers: Bool

    private var rowHeight: CGFloat {
        metrics.rowHeight(weekCount: grid.weeks.count)
    }

    var body: some View {
        switch metrics.sizing {
        case .fill:
            weekRows
        case .square:
            ScrollView(.vertical) {
                weekRows
            }
        }
    }

    private var weekRows: some View {
        VStack(spacing: 0) {
            ForEach(grid.weeks.indices, id: \.self) { weekIndex in
                MonthWeekRowView(
                    days: grid.weeks[weekIndex],
                    today: today,
                    layout: weekLayouts?[safe: weekIndex],
                    metrics: metrics,
                    rowHeight: rowHeight,
                    showWeekNumber: showWeekNumbers,
                    monthInterval: grid.monthInterval
                )
            }
        }
    }
}
