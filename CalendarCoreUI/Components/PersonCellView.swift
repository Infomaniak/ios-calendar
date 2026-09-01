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

public struct ParticipantCellView: View {
    @Environment(\.esdsTheme) private var theme

    let rawAvatarURL: String?
    let displayName: String
    let email: String
    let avatarSize: CGFloat
    let isOrganizer: Bool
    let status: UIParticipationStatus

    public init(
        rawAvatarURL: String?,
        displayName: String,
        email: String,
        avatarSize: CGFloat = 40,
        isOrganizer: Bool,
        status: UIParticipationStatus
    ) {
        self.rawAvatarURL = rawAvatarURL
        self.displayName = displayName
        self.email = email
        self.avatarSize = avatarSize
        self.isOrganizer = isOrganizer
        self.status = status
    }

    public var body: some View {
        PersonCellView(
            rawAvatarURL: rawAvatarURL,
            displayName: displayName,
            email: email,
            avatarSize: avatarSize
        ) {
            HStack(spacing: 0) {
                Text(status.name)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(status.color(theme: theme))

                if isOrganizer {
                    Text(" • \(CalendarResourcesStrings.sectionOrganizerHeader)")
                        .font(.footnote)
                        .foregroundStyle(theme.color.contentPrimary)
                }
            }
        }
    }
}

public struct AccountCellView: View {
    let rawAvatarURL: String?
    let displayName: String
    let email: String
    let avatarSize: CGFloat

    public init(
        rawAvatarURL: String?,
        displayName: String,
        email: String,
        avatarSize: CGFloat = 40
    ) {
        self.rawAvatarURL = rawAvatarURL
        self.displayName = displayName
        self.email = email
        self.avatarSize = avatarSize
    }

    public var body: some View {
        PersonCellView<EmptyView>(
            rawAvatarURL: rawAvatarURL,
            displayName: displayName,
            email: email,
            avatarSize: avatarSize
        )
    }
}

private struct PersonCellView<AdditionalContent: View>: View {
    @Environment(\.esdsTheme) private var theme

    let rawAvatarURL: String?
    let displayName: String
    let email: String
    let avatarSize: CGFloat

    private let additionalContent: AdditionalContent?

    init(
        rawAvatarURL: String?,
        displayName: String,
        email: String,
        avatarSize: CGFloat = 40,
        @ViewBuilder additionalContent: () -> AdditionalContent
    ) {
        self.rawAvatarURL = rawAvatarURL
        self.displayName = displayName
        self.email = email
        self.avatarSize = avatarSize
        self.additionalContent = additionalContent()
    }

    init(
        rawAvatarURL: String?,
        displayName: String,
        email: String,
        avatarSize: CGFloat = 40
    ) {
        self.rawAvatarURL = rawAvatarURL
        self.displayName = displayName
        self.email = email
        self.avatarSize = avatarSize
        additionalContent = nil
    }

    var body: some View {
        HStack {
            AvatarView(rawAvatarURL: rawAvatarURL, displayName: displayName, email: email, size: avatarSize)

            VStack(alignment: .leading, spacing: 0) {
                Text(displayName)
                    .foregroundStyle(theme.color.contentPrimary)

                if displayName != email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(theme.color.contentSecondary)
                }

                if let additionalContent {
                    additionalContent
                }
            }
            .lineLimit(1)
        }
    }
}
