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
import ESDSFoundation
import InfomaniakCoreSwiftUI
import SwiftUI

struct ParticipantsRow: View {
    @Environment(\.esdsTheme) private var theme

    @State private var showParticipants = false

    let attendees: [UIAttendee]

    private var attendeesListForStack: [UIAttendee] {
        Array(attendees.prefix(4))
    }

    private var participationSummary: String {
        let formatters: [UIParticipationStatus: (Int) -> String] = [
            .accepted: CalendarResourcesStrings.attendeesAcceptedCount,
            .tentative: CalendarResourcesStrings.attendeesTentativeCount,
            .needsAction: CalendarResourcesStrings.attendeesPendingCount,
            .declined: CalendarResourcesStrings.attendeesDeclinedCount
        ]

        return UIParticipationStatus.allCases.compactMap { status in
            let count = attendees.count { $0.status == status }
            return count > 0 ? formatters[status]?(count) : nil
        }.joined(separator: ", ")
    }

    var body: some View {
        Button {
            showParticipants = true
        } label: {
            HStack(spacing: 0) {
                Label {
                    VStack(alignment: .leading) {
                        Text(CalendarResourcesStrings.participantsLabel(attendees.count))
                            .font(.body)

                        Text(participationSummary)
                            .font(.subheadline)
                            .foregroundStyle(theme.color.contentSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } icon: {
                    CalendarResourcesAsset.Images.usersStacked.swiftUIImage
                }
                .labelStyle(.formLabel)

                attendeesAvatarStack

                CalendarResourcesAsset.Images.chevronRight.swiftUIImage
                    .iconSize(IKIconSize.large)
                    .foregroundStyle(theme.color.contentTertiary)
            }
        }
        .navigationDestination(isPresented: $showParticipants) {
            ParticipantsListView(uniqueAttendees: attendees)
        }
    }

    private var attendeesAvatarStack: some View {
        HStack(spacing: -IKPadding.mini) {
            ForEach(attendeesListForStack) { attendee in
                AvatarView(
                    rawAvatarURL: nil,
                    displayName: attendee.displayName ?? attendee.email,
                    email: attendee.email,
                    size: IKIconSize.large.rawValue
                )
            }

            if attendees.count > 4 {
                InitialsView(
                    initials: "+\(attendees.count - 4)",
                    backgroundColor: theme.color.backgroundElevationSurfacePressed,
                    foregroundColor: theme.color.backgroundBrandDefault,
                    size: IKIconSize.large.rawValue
                )
            }
        }
        .compositingGroup()
        .padding(.trailing, IKPadding.micro)
    }
}
