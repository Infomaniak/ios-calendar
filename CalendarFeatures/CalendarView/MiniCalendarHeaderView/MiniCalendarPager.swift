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

struct MiniCalendarPager: View {
    let displayMode: MiniCalendarView.DisplayMode

    @Binding var selectedDate: Date
    @Binding var displayedDate: Date

    private var periodOffsets: Range<Int> {
        switch displayMode {
        case .month:
            return -1200 ..< 1201
        case .week:
            return -5200 ..< 5201
        }
    }

    var body: some View {
        CalendarPeriodPager(
            component: displayMode.referenceDateInterval,
            periodOffsets: periodOffsets,
            date: $displayedDate
        ) { date in
            switch displayMode {
            case .month:
                MonthHeaderView(referenceDate: date, selectedDate: $selectedDate)
            case .week:
                WeekHeaderView(referenceDate: date, selectedDate: $selectedDate)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
