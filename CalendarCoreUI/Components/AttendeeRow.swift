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
import InfomaniakCoreSwiftUI
import SwiftUI

public struct AttendeeRow: View {
    let attendee: UIAttendee
    let isOrganizer: Bool

    private var displayName: String {
        attendee.displayName ?? attendee.email
    }

    private var shouldShowEmail: Bool {
        displayName != attendee.email
    }

    public var body: some View {
        HStack(spacing: IKPadding.medium) {
            AvatarView(
                rawAvatarURL: nil,
                displayName: attendee.displayName ?? attendee.email,
                email: attendee.email,
                size: IKIconSize.large.rawValue
            )

            VStack(alignment: .leading, spacing: IKPadding.micro) {
                HStack(spacing: IKPadding.mini) {
                    Text(displayName)

                    if isOrganizer {
                        Text(CalendarResourcesStrings.sectionOrganizerHeader)
                            .font(.caption2)
                            .padding(.horizontal, IKPadding.mini)
                            .padding(.vertical, IKPadding.micro)
                            .background(.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                if shouldShowEmail {
                    Text(attendee.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
