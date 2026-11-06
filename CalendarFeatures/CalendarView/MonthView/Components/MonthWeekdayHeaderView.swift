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

struct MonthWeekdayHeaderView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let weekNumberWidth: CGFloat?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(calendar.orderedWeekdayIndices, id: \.self) { weekdayIndex in
                Text(calendar.shortStandaloneWeekdaySymbols[weekdayIndex])
                    .textCase(.uppercase)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.color.contentPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.leading, weekNumberWidth ?? 0)
        .padding(.vertical, value: .mini)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    MonthWeekdayHeaderView(weekNumberWidth: 24)
}
