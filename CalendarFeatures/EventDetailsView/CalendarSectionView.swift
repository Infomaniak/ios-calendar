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
import InfomaniakCoreSwiftUI
import SwiftUI

struct CalendarSectionView: View {
    let calendar: UICalendar?
    let event: CalendarCoreUI.UIEvent

    var body: some View {
        Section {
            if let calendar {
                LabeledContent {
                    HStack {
                        Circle()
                            .fill(calendar.color)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)

                        Text(calendar.displayName)
                            .lineLimit(1)
                    }
                } label: {
                    Text(CalendarResourcesStrings.sectionCalendarHeader)
                }
            }

            LabeledContent {
                Circle()
                    .fill(event.colors.onDatavizContainerVariant)
                    .frame(
                        width: IKIconSize.medium.rawValue,
                        height: IKIconSize.medium.rawValue
                    )

            } label: {
                Text(CalendarResourcesStrings.eventColorLabel)
            }
            .accessibilityHidden(true)
        } header: {
            Text(CalendarResourcesStrings.sectionCalendarHeader)
        }
    }
}
