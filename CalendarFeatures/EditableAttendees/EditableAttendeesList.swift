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

import CalendarCore
import CalendarCoreUI
import CalendarResources
import ESDSFoundation
import ESDSSymbols
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

private extension View {
    @ViewBuilder
    func searchableIfWritable(_ isWritable: Bool, text: Binding<String>, isPresented: Binding<Bool>,
                              prompt: String) -> some View {
        if isWritable {
            searchable(text: text, isPresented: isPresented, prompt: prompt)
        } else {
            self
        }
    }
}

public struct EditableAttendeesList: View {
    @State private var search = ""
    @State private var isSearching = false

    @State private var searchedAttendees: [UIAttendee]?

    @Binding var attendees: [Attendee]

    let isWritable: Bool

    private var uiAttendees: [UIAttendee] {
        attendees.map { UIAttendee(attendee: $0) }
    }

    private var trimmedSearch: String {
        search.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public init(attendees: Binding<[Attendee]>, isWritable: Bool) {
        _attendees = attendees
        self.isWritable = isWritable
    }

    public var body: some View {
        List {
            if !trimmedSearch.isEmpty, let searchedAttendees {
                ForEach(searchedAttendees, id: \.self) { attendee in
                    SearchResultRow(attendee: attendee, alreadyExist: false, equalAttendeeAlreadyExist: false) {
                        addAttendee(attendee)
                    }
                }

                CustomAttendeeRow(text: trimmedSearch) {
                    addAttendee(UIAttendee(displayName: nil, email: trimmedSearch.lowercased(), status: .needsAction))
                }
            } else {
                ForEach(uiAttendees) { attendee in
                    ParticipantCellView(attendee: attendee)
                }
                .onDelete { indexSet in
                    attendees.remove(atOffsets: indexSet)
                }
                .deleteDisabled(!isWritable)
            }
        }
        .overlay {
            if trimmedSearch.isEmpty && attendees.isEmpty {
                ContentUnavailableView {
                    Label("!No Attendees", symbol: .calendarUser)
                } description: {
                    Text("!Search for contatcs to add them to the event.")
                }
            }
        }
        .searchableIfWritable(isWritable, text: $search, isPresented: $isSearching, prompt: "!Add an attendee")
        .task(id: trimmedSearch) {
            await searchContacts(query: trimmedSearch)
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(CalendarResourcesStrings.participantsLabel(attendees.count))
    }

    private func searchContacts(query: String) async {
        guard !query.isEmpty else {
            searchedAttendees = nil
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(300))

            @InjectService var calendarSDK: CalendarCoreGraph
            let results = try await calendarSDK.contactsManager.search(query: query)
            guard !Task.isCancelled else { return }

            let currentAttendees = uiAttendees
            searchedAttendees = results.map { result in
                let contact = UIContact(contact: result)
                let email = contact.email.lowercased()
                if let existingAttendee = currentAttendees.first(where: { $0.email == email && $0.displayName == contact.name }) {
                    return existingAttendee
                }
                return UIAttendee(displayName: contact.name, email: email, status: .needsAction, contact: contact)
            }
        } catch {
            guard !Task.isCancelled else { return }
            searchedAttendees = nil
        }
    }

    private func addAttendee(_ uiAttendee: UIAttendee) {
        guard !attendees.contains(where: { $0.email.lowercased() == uiAttendee.email }) else { return }

        let attendee = Attendee(
            email: uiAttendee.email,
            displayName: uiAttendee.displayName,
            status: .needsAction,
            role: .requested,
            isOrganizer: false,
            responseNeeded: true,
            type: .individual,
            contact: nil // fix
        )

        withAnimation {
            attendees.append(attendee)

            search = ""
            isSearching = false
        }
    }
}

#Preview {
    NavigationStack {
        EditableAttendeesList(attendees: .constant([]), isWritable: true)
    }
}
