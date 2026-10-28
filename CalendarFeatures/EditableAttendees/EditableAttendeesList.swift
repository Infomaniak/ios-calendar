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

    @State private var searchedContacts: [UIContact]?

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
            if !trimmedSearch.isEmpty, let searchedContacts {
                ForEach(searchedContacts) { contact in
                    AttendeeSearchResultButton(
                        avatar: contact.avatar,
                        name: contact.name,
                        email: contact.email,
                        attendees: uiAttendees
                    ) {
                        addAttendee(email: contact.email, displayName: contact.name, contact: contact)
                    }
                }

                CustomAttendeeRow(text: trimmedSearch) {
                    addAttendee(email: trimmedSearch, displayName: nil, contact: nil)
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
        .searchableIfWritable(isWritable, text: $search, isPresented: $isSearching, prompt: "!Add an attendee")
        .task(id: trimmedSearch) {
            await searchContacts(query: trimmedSearch)
        }
        .toolbarTitleDisplayMode(.inline)
    }

    private func searchContacts(query: String) async {
        guard !query.isEmpty else {
            searchedContacts = nil
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(300))

            @InjectService var calendarSDK: CalendarCoreGraph
            let results = try await calendarSDK.contactsManager.search(query: query)
            guard !Task.isCancelled else { return }

            searchedContacts = results.map { UIContact(contact: $0) }
        } catch {
            guard !Task.isCancelled else { return }
            searchedContacts = nil
        }
    }

    private func addAttendee(email: String, displayName: String?, contact: UIContact?) {
        let email = email.lowercased()
        guard !attendees.contains(where: { $0.email.lowercased() == email }) else { return }

        let attendee = Attendee(
            email: email,
            displayName: displayName,
            status: .needsAction,
            role: .requested,
            isOrganizer: false,
            responseNeeded: true,
            type: .individual,
            contact: nil // fix this
        )

        withAnimation {
            attendees.append(attendee)

            search = ""
            isSearching = false
        }
    }
}

private struct AttendeeSearchResultButton: View {
    let avatar: UIAvatarType?
    let name: String?
    let email: String
    let attendees: [UIAttendee]
    let action: () -> Void

    private var existingAttendee: UIAttendee? {
        attendees.first { $0.email == email.lowercased() }
    }

    private var matchingAttendee: UIAttendee? {
        guard let existingAttendee, existingAttendee.displayName == name else { return nil }
        return existingAttendee
    }

    private var displayName: String {
        guard let name, !name.isEmpty else { return email }
        return name
    }

    var body: some View {
        Button(action: action) {
            ParticipantCellView(
                avatar: avatar ?? matchingAttendee?.contact?.avatar,
                displayName: displayName,
                email: email,
                isOrganizer: matchingAttendee?.isOrganizer ?? false,
                status: matchingAttendee?.status
            )
        }
        .disabled(existingAttendee != nil)
        .opacity(existingAttendee != nil ? 0.5 : 1)
    }
}

#Preview {
    NavigationStack {
        EditableAttendeesList(attendees: .constant([]), isWritable: true)
    }
}
