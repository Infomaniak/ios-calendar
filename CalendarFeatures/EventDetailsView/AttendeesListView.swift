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
import SwiftUI

struct AttendeesListView: View {
    @State private var search = ""

    let attendees: [UIAttendee]

    private var visibleAttendees: [UIAttendee] {
        var filteredAttendees = attendees
        if !search.isEmpty {
            filteredAttendees = attendees.filter {
                $0.displayName?.localizedCaseInsensitiveContains(search) == true ||
                $0.email.localizedCaseInsensitiveContains(search)
            }
        }

        return filteredAttendees.sortedForDisplay()
    }

    var body: some View {
        List {
            ForEach(visibleAttendees.sortedForDisplay()) { attendee in
                ParticipantCellView(
                    rawAvatarURL: nil,
                    displayName: attendee.displayName ?? attendee.email,
                    email: attendee.email,
                    isOrganizer: attendee.isOrganizer,
                    status: attendee.status
                )
            }
        }
        .searchable(text: $search)
        .navigationTitle(CalendarResourcesStrings.participantsLabel(attendees.count))
        .toolbarTitleDisplayMode(.inline)
    }
}

private extension [UIAttendee] {
    func sortedForDisplay() -> [UIAttendee] {
        sorted {
            if $0.isOrganizer != $1.isOrganizer {
                return $0.isOrganizer
            }
            return $0.status.sortOrder < $1.status.sortOrder
        }
    }
}

#Preview {
    AttendeesListView(attendees: UIAttendee.previews)
}
