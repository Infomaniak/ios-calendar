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

import CalendarResources
import DesignSystem
import ESDSFoundation
import SwiftUI

struct WeekHeaderView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let date: Date
    let weekDates: [Date]

    var body: some View {
        HStack(spacing: 0) {
            Text(CalendarResourcesStrings.weekHeaderWeekNumber(calendar.component(.weekOfYear, from: date)))
                .font(.caption2)
                .foregroundStyle(theme.color.contentTertiary)
                .padding(.trailing, value: .small)
                .frame(width: TimelineBackgroundView.Constants.leadingInset, alignment: .trailing)

            ForEach(weekDates, id: \.self) { weekDate in
                LargeDayHeaderView(date: weekDate)
            }
        }
    }
}

#Preview {
    WeekHeaderView(
        date: .now,
        weekDates: (0 ..< 7).compactMap { Calendar.current.date(
            byAdding: .day,
            value: $0,
            to: Calendar.current.weekStart(for: .now)
        ) }
    )
}
