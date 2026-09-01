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

struct ParticipantsListView: View {
    var uniqueAttendees: [UIAttendee]

    var body: some View {
        List {
            ForEach(uniqueAttendees.sortedForDisplay()) { attendee in
                ParticipantCellView(rawAvatarURL: nil,
                                    displayName: attendee.displayName ?? attendee.email,
                                    email: attendee.email,
                                    isOrganizer: attendee.isOrganizer,
                                    status: attendee.status)
            }
        }
        .navigationTitle(CalendarResourcesStrings.participantsLabel(uniqueAttendees.count))
    }
}

private extension [UIAttendee] {
    func sortedForDisplay() -> [UIAttendee] {
        sorted {
            if $0.isOrganizer != $1.isOrganizer { return $0.isOrganizer }
            return $0.status.sortOrder < $1.status.sortOrder
        }
    }
}
