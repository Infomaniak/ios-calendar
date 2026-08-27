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
import SwiftUI

public struct LocationRow: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.esdsTheme) private var theme
    let address: String

    private func openInMaps() {
        guard let url = AppleMapsHelper().addressURL(address) else { return }
        openURL(url)
    }

    public var body: some View {
        Button {
            openInMaps()
        } label: {
            HStack(spacing: IKPadding.medium) {
                CalendarResourcesAsset.Images.mapPin.swiftUIImage
                    .iconSize(IKIconSize.large)
                    .foregroundStyle(theme.color.contentSecondary)
                Text(address)
                    .foregroundStyle(theme.color.contentPrimary)

                Spacer()

                CalendarResourcesAsset.Images.chevronRight.swiftUIImage
                    .iconSize(IKIconSize.large)
                    .foregroundStyle(theme.color.contentTertiary)
            }
        }
    }
}
