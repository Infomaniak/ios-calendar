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
import CalendarResources
import DesignSystem
import ESDSFoundation
import SwiftUI

public struct DayRow: View {
    @Environment(\.esdsTheme) private var theme
    let event: CalendarCoreUI.UIEvent

    private var dateRangeText: Text {
        let dateText = Text(event.startDate, format: .dateTime.month(.wide).day().weekday(.wide))
        let separator = Text(" – ")

        if event.isAllDay {
            return dateText + separator + Text(CalendarResourcesStrings.allDayLabel)
        } else {
            return dateText + separator + Text(event.startDate, format: .dateTime.hour().minute())
        }
    }

    public var body: some View {
        HStack(spacing: IKPadding.medium) {
            CalendarResourcesAsset.Images.clock.swiftUIImage
                .iconSize(IKIconSize.large)
                .foregroundStyle(theme.color.iconSecondary)

            VStack(alignment: .leading) {
                dateRangeText
                    .font(.body)
                    .foregroundStyle(theme.color.textPrimary)

                Text("Chaque semaine le mercredi") // TODO: Use event recurrence
                    .font(.subheadline)
                    .foregroundStyle(theme.color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
