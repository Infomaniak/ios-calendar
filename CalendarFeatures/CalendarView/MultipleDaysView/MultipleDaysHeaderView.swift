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

struct MultipleDaysHeaderView: View {
    /// The header is rendered by the shared top bar, which only refreshes it when its version changes.
    struct Version: Hashable {
        let layout: MultipleDaysLayout
        let weekOfYear: Int
    }

    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let layout: MultipleDaysLayout
    let date: Date
    let pagerScrollSync: CalendarPeriodPagerScrollSync

    var body: some View {
        HStack(spacing: 0) {
            Text(CalendarResourcesStrings.weekHeaderWeekNumber(calendar.component(.weekOfYear, from: date)))
                .font(.caption2)
                .foregroundStyle(theme.color.contentTertiary)
                .padding(.trailing, value: .small)
                .frame(width: TimelineBackgroundView.Constants.leadingInset, alignment: .trailing)

            CalendarPeriodPagerMirror(scrollSync: pagerScrollSync, viewCount: layout.pagerViewCount) { pagerDate in
                HStack(spacing: 0) {
                    ForEach(layout.pageDates(for: pagerDate, calendar: calendar), id: \.self) { day in
                        LargeDayHeaderView(date: day)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, value: .medium)
    }
}
