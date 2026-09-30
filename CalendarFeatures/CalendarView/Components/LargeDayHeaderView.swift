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

struct LargeDayHeaderView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let date: Date

    private var foreground: Color {
        if calendar.isDate(date, inSameDayAs: .now) {
            return theme.color.contentBrand
        } else {
            return theme.color.contentPrimary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(date, format: .dateTime.weekday(.abbreviated))
                .textCase(.uppercase)
                .font(.caption2)

            Text(date, format: .dateTime.day())
                .font(.title3.weight(.emphasized))
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, value: .mini)
    }
}

#Preview {
    LargeDayHeaderView(date: .now)
}
