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
import ESDSSymbols
import SwiftUI

private extension Image {
    func eventSymbol(_ accessibilityLabel: String) -> some View {
        return font(.system(size: EventIconsView.iconSize))
            .accessibilityLabel(Text(accessibilityLabel))
    }
}

struct EventIconsView: View {
    nonisolated static let iconSize: CGFloat = IKIconSize.medium.rawValue

    let hasLocation: Bool
    let hasKMeetLink: Bool
    let hasAttendees: Bool
    let shouldShowLocationIcon: Bool

    init(event: CalendarCoreUI.UIEvent, shouldShowLocationIcon: Bool = true) {
        hasLocation = event.location != nil
        hasKMeetLink = event.kMeetLink != nil
        hasAttendees = !event.attendees.isEmpty
        self.shouldShowLocationIcon = shouldShowLocationIcon
    }

    var body: some View {
        HStack(spacing: IKPadding.micro) {
            if hasLocation && shouldShowLocationIcon {
                ESDSSymbols.mapPin.image
                    .eventSymbol(CalendarResourcesStrings.contentDescriptionHasLocation)
            }
            if hasKMeetLink {
                ESDSSymbols.productKmeet.image
                    .eventSymbol(CalendarResourcesStrings.contentDescriptionHasKMeetLink)
            }
            if hasAttendees {
                ESDSSymbols.usersStacked.image
                    .eventSymbol(CalendarResourcesStrings.contentDescriptionHasAttendees)
            }
        }
    }
}

#Preview {
    EventIconsView(event: .preview)
}
