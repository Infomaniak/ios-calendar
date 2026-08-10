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
import SwiftUI

struct ParticipantsSectionView: View {
    @State private var attendeesListIsOpen = false

    let event: CalendarCoreUI.UIEvent

    private var uniqueAttendees: [UIAttendee] {
        var seenEmails = Set<String>()

        return event.attendees.filter { attendee in
            seenEmails.insert(normalizedEmail(attendee.email)).inserted
        }
    }

    private var visibleAttendees: [UIAttendee] {
        Array(uniqueAttendees.prefix(3))
    }

    private func isOrganizer(_ attendee: UIAttendee) -> Bool {
        return attendee.isOrganizer
    }

    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        if !uniqueAttendees.isEmpty {
            Section {
                DisclosureGroup(isExpanded: $attendeesListIsOpen) {
                    ForEach(uniqueAttendees) { attendee in
                        AttendeeRow(attendee: attendee, isOrganizer: isOrganizer(attendee))
                    }
                } label: {
                    HStack(spacing: IKPadding.micro) {
                        HStack(spacing: -IKIconSize.medium.rawValue / 3) {
                            ForEach(Array(visibleAttendees.enumerated()), id: \.element) { attendee in
                                AvatarView(rawAvatarURL: nil,
                                           displayName: attendee.element.displayName ?? attendee.element.email,
                                           email: attendee.element.email,
                                           size: IKIconSize.medium.rawValue)
                            }
                        }
                        .compositingGroup()

                        Text(CalendarResourcesStrings.participantsLabel(uniqueAttendees.count))
                    }
                }
            } header: {
                Text(CalendarResourcesStrings.sectionParticipantsHeader)
            }
        }
    }
}
