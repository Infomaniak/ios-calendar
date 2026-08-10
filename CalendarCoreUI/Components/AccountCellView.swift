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
import InfomaniakCore
import InfomaniakCoreSwiftUI
import SwiftUI

public struct AccountCellView: View {
    @Environment(\.esdsTheme) private var theme

    let rawAvatarURL: String?
    let displayName: String
    let email: String
    let avatarSize: CGFloat
    let isOrganizer: Bool

    public init(rawAvatarURL: String?, displayName: String, email: String, avatarSize: CGFloat = 40, isOrganizer: Bool = false) {
        self.rawAvatarURL = rawAvatarURL
        self.displayName = displayName
        self.email = email
        self.avatarSize = avatarSize
        self.isOrganizer = isOrganizer
    }

    public var body: some View {
        HStack {
            AvatarView(rawAvatarURL: rawAvatarURL, displayName: displayName,
                       email: email, size: avatarSize)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: IKPadding.mini) {
                    Text(displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(theme.color.textPrimary)

                    if isOrganizer {
                        Text(CalendarResourcesStrings.sectionOrganizerHeader)
                            .font(.caption2)
                            .padding(.horizontal, IKPadding.mini)
                            .padding(.vertical, IKPadding.micro)
                            .background(.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text(email)
                    .font(.body)
                    .foregroundStyle(theme.color.textSecondary)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
