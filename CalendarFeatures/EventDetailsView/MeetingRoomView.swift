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

public struct MeetingRoomView: View {
    @Environment(\.esdsTheme) private var theme
    let roomTitle: String
    let roomFloor: Int
    let roomCapacity: Int

    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    public var body: some View {
        HStack {
            CalendarResourcesAsset.Images.doorOpen.swiftUIImage
                .iconSize(IKIconSize.large)
                .foregroundStyle(theme.color.iconSecondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(roomTitle)
                    .font(.body.weight(.regular))
                    .foregroundStyle(theme.color.textPrimary)

                HStack(spacing: IKPadding.mini) {
                    CalendarResourcesAsset.Images.usersStacked.swiftUIImage
                        .iconSize(IKIconSize.medium)
                        .foregroundStyle(theme.color.iconSecondary)
                    Text(CalendarResourcesStrings.roomSeatsLabel(roomCapacity))
                        .padding(.trailing, IKPadding.mini)
                        .font(.subheadline.weight(.regular))
                        .foregroundStyle(theme.color.textSecondary)

                    CalendarResourcesAsset.Images.stair.swiftUIImage
                        .iconSize(IKIconSize.medium)
                        .foregroundStyle(theme.color.iconSecondary)

                    let floor = Self.ordinalFormatter.string(from: roomFloor as NSNumber) ?? "\(roomFloor)"
                    Text(CalendarResourcesStrings.roomFloorLabel(floor))
                        .font(.subheadline.weight(.regular))
                        .foregroundStyle(theme.color.textSecondary)
                }
            }
            .padding(.trailing, IKPadding.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MeetingRoomView(roomTitle: "Salle Jules Verne", roomFloor: 3, roomCapacity: 20)
}
