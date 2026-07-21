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
import ESDSCalendar
import SwiftUI

struct NoEventsCellView: View {
    @Environment(\.esdsTheme) private var theme

    var body: some View {
        Text(CalendarResourcesStrings.planningNothingPlanned)
            .font(.caption.weight(.medium))
            .foregroundStyle(theme.color.textPrimary)
            .padding(.horizontal, value: .medium)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NoEventsCellView()
}
