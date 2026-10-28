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
import MultiplatformCalendar
import SwiftUI

struct EditableAttendeesList: View {
    @State private var search = ""

    @Binding var attendees: [Attendee]

    var body: some View {
        List {
            ForEach(attendees.map { UIAttendee(attendee: $0) }) { attendee in
                ParticipantCellView(
                    avatar: attendee.contact?.avatar,
                    displayName: attendee.displayName ?? attendee.email,
                    email: attendee.email,
                    isOrganizer: attendee.isOrganizer,
                    status: attendee.status
                )
            }
            .onDelete { indexSet in
                attendees.remove(atOffsets: indexSet)
            }
        }
        .searchable(text: $search, prompt: "!Add an attendee")
        .navigationTitle(CalendarResourcesStrings.attendeesTitle)
        .toolbarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EditableAttendeesList(attendees: .constant([]))
    }
}
