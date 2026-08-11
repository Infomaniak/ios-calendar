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

struct ParticipantsSectionView: View {
    @Environment(\.esdsTheme) private var theme

    @State private var attendeesListIsOpen = false

    var uniqueAttendees: [UIAttendee]

    private var visibleAttendees: [UIAttendee] {
        Array(uniqueAttendees.prefix(4))
    }

    private var participationSummary: String {
        let formatters: [UIParticipationStatus: (Int) -> String] = [
            .accepted: CalendarResourcesStrings.attendeesAcceptedCount,
            .tentative: CalendarResourcesStrings.attendeesTentativeCount,
            .needsAction: CalendarResourcesStrings.attendeesPendingCount,
            .declined: CalendarResourcesStrings.attendeesDeclinedCount
        ]

        return UIParticipationStatus.allCases.compactMap { status in
            let count = uniqueAttendees.filter { $0.status == status }.count
            return count > 0 ? formatters[status]?(count) : nil
        }.joined(separator: ", ")
    }

    var body: some View {
        if !uniqueAttendees.isEmpty {
            DisclosureGroup(isExpanded: $attendeesListIsOpen) {
                ForEach(uniqueAttendees) { attendee in
                    AttendeeRow(attendee: attendee, isOrganizer: attendee.isOrganizer)
                }
            } label: {
                HStack(spacing: 0) {
                    CalendarResourcesAsset.Images.usersStacked.swiftUIImage
                        .iconSize(IKIconSize.large)
                        .foregroundStyle(theme.color.iconSecondary)

                    VStack(alignment: .leading) {
                        Text(CalendarResourcesStrings.participantsLabel(uniqueAttendees.count))
                            .font(.body)
                            .foregroundStyle(theme.color.textPrimary)

                        Text(participationSummary)
                            .font(.subheadline)
                            .foregroundStyle(theme.color.textSecondary)
                    }
                    .padding(.leading, IKPadding.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: -IKPadding.mini) {
                        ForEach(Array(visibleAttendees.enumerated()), id: \.element) { attendee in
                            AvatarView(rawAvatarURL: nil,
                                       displayName: attendee.element.displayName ?? attendee.element.email,
                                       email: attendee.element.email,
                                       size: IKIconSize.large.rawValue)
                        }
                        if uniqueAttendees.count > 4 {
                            InitialsView(initials: "+\(uniqueAttendees.count - 4)",
                                         backgroundColor: theme.color.backgroundElevationSurfacePressed,
                                         foregroundColor: .accentColor,
                                         size: IKIconSize.large.rawValue)
                        }
                    }
                    .compositingGroup()
                    .padding(.trailing, IKPadding.micro)
                }
            }
        }
    }
}
