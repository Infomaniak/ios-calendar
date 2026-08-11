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
import SwiftUI

struct MiniCalendarView: View {
    enum DisplayMode {
        case month
        case week
    }

    @Binding var displayMode: DisplayMode
    @Binding var selectedDate: Date
    @Binding var displayedDate: Date

    var body: some View {
        VStack(spacing: IKPadding.micro) {
            DayOfWeekView()
            if displayMode == .week {
                InfiniteScrollView(
                    referenceDateInterval: .weekOfYear,
                    selectedDate: $selectedDate,
                    displayedDate: $displayedDate
                ) { date in
                    WeekHeaderView(startDate: date, selectedDate: $selectedDate)
                }
            } else {
                InfiniteScrollView(
                    referenceDateInterval: .month,
                    selectedDate: $selectedDate,
                    displayedDate: $displayedDate
                ) { date in
                    MonthHeaderView(startDate: date, selectedDate: $selectedDate)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    @Previewable @State var displayMode: MiniCalendarView.DisplayMode = .week
    @Previewable @State var selectedDate = Date()
    @Previewable @State var displayedDate = Date()
    MiniCalendarView(displayMode: $displayMode, selectedDate: $selectedDate, displayedDate: $displayedDate)
}
