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

import CalendarCore
import CalendarResources
import DesignSystem
import ESDSFoundation
import ESDSSymbols
import InfomaniakCoreSwiftUI
import SwiftUI

public struct MeetingRoomView: View {
    @Environment(\.esdsTheme) private var theme
    let roomTitle: String
    let roomFloor: Int?
    let roomCapacity: Int?
    let availability: MeetingRoomAvailability

    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    public init(roomTitle: String, roomFloor: Int?, roomCapacity: Int?, availability: MeetingRoomAvailability) {
        self.roomTitle = roomTitle
        self.roomFloor = roomFloor
        self.roomCapacity = roomCapacity
        self.availability = availability
    }

    public var body: some View {
        HStack(spacing: IKPadding.small) {
            Label {
                VStack(alignment: .leading, spacing: IKPadding.mini) {
                    Text(roomTitle)
                        .font(.body.weight(.regular))
                        .foregroundStyle(theme.color.contentPrimary)

                    if roomCapacity != nil || roomFloor != nil {
                        HStack(spacing: IKPadding.mini) {
                            if let roomCapacity {
                                ESDSSymbols.usersStacked.image
                                    .font(.system(size: IKIconSize.medium.rawValue))
                                    .foregroundStyle(theme.color.contentSecondary)
                                    .accessibilityHidden(true)
                                Text(CalendarResourcesStrings.roomSeatsLabel(roomCapacity))
                                    .padding(.trailing, IKPadding.mini)
                                    .font(.subheadline.weight(.regular))
                                    .foregroundStyle(theme.color.contentSecondary)
                            }

                            if let roomFloor {
                                ESDSSymbols.zigzagArrowUpRight.image
                                    .font(.system(size: IKIconSize.medium.rawValue))
                                    .foregroundStyle(theme.color.contentSecondary)
                                    .accessibilityHidden(true)

                                let floor = Self.ordinalFormatter.string(from: roomFloor as NSNumber) ?? "\(roomFloor)"
                                Text(CalendarResourcesStrings.roomFloorLabel(floor))
                                    .font(.subheadline.weight(.regular))
                                    .foregroundStyle(theme.color.contentSecondary)
                            }
                        }
                    }
                }
                .padding(.trailing, IKPadding.large)
            } icon: {
                ESDSSymbols.doorOpen.image
            }
            .labelStyle(.formLabel)
            .frame(maxWidth: .infinity, alignment: .leading)

            Circle()
                .fill(availability.color(theme: theme))
                .frame(width: IKIconSize.small.rawValue, height: IKIconSize.small.rawValue)
                .accessibilityLabel(availability.accessibilityLabel)
        }
    }
}

#Preview {
    Form {
        MeetingRoomView(roomTitle: "Salle Jules Verne", roomFloor: 3, roomCapacity: 20, availability: .available)
        MeetingRoomView(roomTitle: "Salle Jules Verne", roomFloor: 3, roomCapacity: 20, availability: .unavailable)
        MeetingRoomView(roomTitle: "Salle Jules Verne", roomFloor: 3, roomCapacity: 20, availability: .unknown)
    }
}
