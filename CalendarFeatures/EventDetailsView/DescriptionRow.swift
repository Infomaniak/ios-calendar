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

struct DescriptionRow: View {
    @Environment(\.esdsTheme) private var theme

    @State private var isExpanded = false
    @State private var isTruncated = false
    @State private var fullHeight: CGFloat = 0

    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            CalendarResourcesAsset.Images.listLeft.swiftUIImage
                .iconSize(IKIconSize.large)
                .accessibilityHidden(true)
                .foregroundStyle(theme.color.contentSecondary)
                .padding(.trailing, IKPadding.medium)

            VStack(alignment: .leading) {
                Text(CalendarResourcesStrings.descriptionTitle)
                    .foregroundStyle(theme.color.contentPrimary)

                Text(description)
                    .lineLimit(isExpanded ? nil : 2)
                    .textSelection(.enabled)
                    .foregroundStyle(theme.color.contentSecondary)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { visibleHeight in
                        if fullHeight > visibleHeight + 1 {
                            isTruncated = true
                        } else if !isExpanded {
                            isTruncated = false
                        }
                    }
                    .background(
                        Text(description)
                            .fixedSize(horizontal: false, vertical: true)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullHeight = $0 }
                            .hidden()
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isTruncated {
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .foregroundStyle(theme.color.contentTertiary)
                    .frame(height: 20, alignment: .center)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(.rect)
        .onTapGesture {
            guard isTruncated else { return }
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
}
