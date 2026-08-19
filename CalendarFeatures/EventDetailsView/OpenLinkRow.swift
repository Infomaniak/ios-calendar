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

public struct OpenLinkRow: View {
    @Environment(\.esdsTheme) private var theme
    @Environment(\.openURL) private var openURL

    let title: String
    let buttonTitle: String
    let icon: Image
    let linkURL: URL
    let showLink: Bool

    public var body: some View {
        HStack(spacing: 0) {
            icon
                .iconSize(IKIconSize.large)
                .foregroundStyle(theme.color.contentSecondary)
                .padding(.trailing, IKPadding.medium)

            VStack(alignment: .leading) {
                Text(title)
                    .foregroundStyle(theme.color.contentPrimary)

                if showLink {
                    Text("\(linkURL.absoluteString)")
                        .lineLimit(1)
                        .font(.footnote)
                        .foregroundStyle(theme.color.contentSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                openURL(linkURL)
            } label: {
                Text(buttonTitle)
                    .foregroundStyle(theme.color.backgroundBrandDefault)
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(theme.color.backgroundBrandDefault.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, IKPadding.medium)

            ShareLink(item: linkURL) {
                CalendarResourcesAsset.Images.squareArrowOutUpRight.swiftUIImage
                    .iconSize(IKIconSize.large)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
