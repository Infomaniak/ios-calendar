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
import ESDSFoundation
import SwiftUI

struct PlanningWeekHeaderView: View {
    @Environment(\.esdsTheme) private var theme
    @Environment(\.calendar) private var calendar

    let date: Date

    private var weekInterval: Range<Date>? {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: date) else { return nil }
        return interval.start ..< interval.end.addingTimeInterval(-1)
    }

    var body: some View {
        if let weekInterval {
            HStack {
                Text(CalendarResourcesStrings.weekHeaderWeekNumber(calendar.component(.weekOfYear, from: date)))
                    .font(.system(.caption2))
                    .foregroundStyle(theme.color.contentTertiary)

                Text(weekInterval, format: .interval.day().month(.wide))
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(theme.color.contentPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    PlanningWeekHeaderView(date: Date())
}
