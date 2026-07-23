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
import UIKit

struct WeekOrMonthView: View {
    @Namespace private var weeksOrMonthViewNamespace

    @Environment(\.calendar) private var calendar

    enum DisplayMode {
        case month
        case week
    }

    let startDate: Date
    let displayMode: DisplayMode

    private var monthStart: Date {
        calendar.monthStart(for: startDate)
    }

    private var gridStart: Date {
        displayMode == .week ? startDate : calendar.weekStart(for: monthStart)
    }

    private var rowCount: Int {
        guard displayMode == .month,
              let monthEnd = calendar.dateInterval(of: .month, for: monthStart)?.end else {
            return 1
        }

        let dayCount = calendar.dateComponents([.day], from: gridStart, to: monthEnd).day ?? 0
        return min(max((dayCount + 6) / 7, 4), 6)
    }

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0 ..< rowCount, id: \.self) { row in
                let weekStartDay = calendar.date(byAdding: .day, value: row * 7, to: gridStart)
                GridRow {
                    HStack {
                        ForEach(0 ..< 7, id: \.self) { column in
                            let dayIndex = row * 7 + column

                            ZStack {
                                if let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: gridStart) {
                                    if displayMode == .week || calendar.isDate(
                                        dayDate,
                                        equalTo: monthStart,
                                        toGranularity: .month
                                    ) {
                                        DayCellView(date: dayDate)
                                    } else {
                                        DayCellView(date: dayDate)
                                            .opacity(0.5)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .geometryGroup()
                    .matchedGeometryEffect(id: weekStartDay, in: weeksOrMonthViewNamespace)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WeekOrMonthView(startDate: Calendar.current.weekStart(for: Date()), displayMode: .week)
}

#Preview {
    WeekOrMonthView(startDate: Calendar.current.monthStart(for: Date()), displayMode: .month)
}

#Preview {
    @Previewable @State var displayMode: WeekOrMonthView.DisplayMode = .week
    @Previewable @State var startDate: Date = Calendar.current.weekStart(for: Date())
    VStack {
        WeekOrMonthView(startDate: startDate, displayMode: displayMode)
        Button("Toggle Display Mode") {
            withAnimation {
                displayMode = (displayMode == .week) ? .month : .week
                startDate = (displayMode == .week) ? Calendar.current.weekStart(for: Date()) : Calendar.current
                    .monthStart(for: Date())
            }
        }
    }
}
