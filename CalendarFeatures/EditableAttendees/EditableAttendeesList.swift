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
    func searchableIfWritable(
        _ isWritable: Bool, text: Binding<String>, isPresented: Binding<Bool>, prompt: String
    ) -> some View {
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

    private var isShowingSearchResults: Bool {
        searchedAttendees != nil
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
            ForEach(searchedAttendees ?? uiAttendees) { attendee in
                EditableAttendeeRow(
                    attendee: attendee,
                    addedState: addedState(of: attendee, in: uiAttendees),
                    action: isShowingSearchResults ? { addAttendee(attendee) } : nil
                )
            }
            .onDelete { attendees.remove(atOffsets: $0) }
            .deleteDisabled(!isWritable || isShowingSearchResults)

            if isShowingSearchResults && !trimmedSearch.isEmpty {
                CustomAttendeeRow(text: trimmedSearch) {
                    addAttendee(UIAttendee(displayName: nil, email: trimmedSearch.lowercased(), status: .needsAction))
                }
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

    private func addedState(of attendee: UIAttendee, in addedAttendees: [UIAttendee]) -> AttendeeAddedState {
        if addedAttendees.contains(where: { $0.id == attendee.id }) {
            return .sameAttendee
        } else if addedAttendees.contains(where: { $0.email == attendee.email }) {
            return .sameEmail
        }
        return .notAdded
    }

    private func searchContacts(query: String) async {
        guard !trimmedSearch.isEmpty else {
            withAnimation { searchedAttendees = nil }
            return
        }

        do {
            @InjectService var calendarSDK: CalendarCoreGraph
            let results = try await calendarSDK.contactsManager.search(query: query)
            guard !Task.isCancelled else { return }

            let currentAttendees = uiAttendees
            var seenIds = Set<String>()
            let newSearchedAttendees = results.compactMap { result -> UIAttendee? in
                let contact = UIContact(contact: result)
                let email = contact.email.lowercased()
                let attendee = currentAttendees.first { $0.email == email && $0.displayName == contact.name }
                    ?? UIAttendee(displayName: contact.name, email: email, status: .needsAction, contact: contact)
                return seenIds.insert(attendee.id).inserted ? attendee : nil
            }

            withAnimation { searchedAttendees = newSearchedAttendees }
        } catch {
            guard !Task.isCancelled else { return }
            withAnimation { searchedAttendees = nil }
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
            contact: uiAttendee.contact.map { $0.sdkValue }
        )

        withAnimation {
            attendees.append(attendee)

            search = ""
            searchedAttendees = nil
            isSearching = false
        }
    }
}

#Preview {
    NavigationStack {
        EditableAttendeesList(attendees: .constant([]), isWritable: true)
    }
}
