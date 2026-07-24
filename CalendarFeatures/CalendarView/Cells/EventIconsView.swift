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
import SwiftUI

struct EventIconsView: View {
    let hasLocation: Bool
    let hasKMeetLink: Bool
    let hasAttendees: Bool

    static let iconSize: CGFloat = IKIconSize.medium.rawValue

    init(event: CalendarCoreUI.UIEvent) {
        hasLocation = event.location != nil
        hasKMeetLink = event.kMeetLink != nil
        hasAttendees = !event.attendees.isEmpty
    }

    var body: some View {
        HStack(spacing: IKPadding.micro) {
            if hasLocation {
                CalendarResourcesAsset.Images.mapPin.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: Self.iconSize, maxHeight: Self.iconSize)
                    .accessibilityLabel(Text(CalendarResourcesStrings.contentDescriptionHasLocation))
            }
            if hasKMeetLink {
                CalendarResourcesAsset.Images.productKmeet.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: Self.iconSize, maxHeight: Self.iconSize)
                    .accessibilityLabel(Text(CalendarResourcesStrings.contentDescriptionHasKMeetLink))
            }
            if !hasAttendees {
                CalendarResourcesAsset.Images.usersStacked.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: Self.iconSize, maxHeight: Self.iconSize)
                    .accessibilityLabel(Text(CalendarResourcesStrings.contentDescriptionHasAttendees))
            }
        }
    }
}

#Preview {
    EventIconsView(event: .preview)
}
