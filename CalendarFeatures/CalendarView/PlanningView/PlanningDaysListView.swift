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
import SwiftUI

struct PlanningDaysListView: View, Equatable {
    /// Point below the scroll view's top edge used to find the top-most visible day, tolerating sub-point rounding.
    private nonisolated static let topProbeY: CGFloat = 1

    let periods: CalendarPeriodCollection
    let eventsByDay: [Date: [UIEventSummary]]
    @Binding var visibleDay: Int?

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(periods) { period in
                let date = period.date
                PlanningDayRowView(date: date, events: eventsByDay[date] ?? [])
                    .onGeometryChange(for: Bool.self) { proxy in
                        let frame = proxy.frame(in: .scrollView)
                        return frame.minY <= Self.topProbeY && frame.maxY > Self.topProbeY
                    } action: { isAtTop in
                        if isAtTop {
                            visibleDay = period.id
                        }
                    }
            }
        }
    }

    nonisolated static func == (lhs: PlanningDaysListView, rhs: PlanningDaysListView) -> Bool {
        lhs.periods == rhs.periods && lhs.eventsByDay == rhs.eventsByDay
    }
}
