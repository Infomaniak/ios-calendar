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
import InfomaniakCore
import InfomaniakDI
import MultiplatformCalendar
import OrderedCollections
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

    @State private var searchedAttendees: OrderedSet<UIAttendee>?

    @Binding var attendees: [Attendee]
    @Binding var organizer: Organizer?

    let currentUser: UserProfile?
    let isWritable: Bool

    private let validator = EventDraftValidator()

    private var isAttendeeLimitReached: Bool {
        attendees.count >= EventDraftValidator.maximumAttendeeCount
    }

    private var uiAttendees: OrderedSet<UIAttendee> {
        return OrderedSet(attendees.map { UIAttendee(attendee: $0) })
    }

    private var isShowingSearchResults: Bool {
        searchedAttendees != nil
    }

    private var trimmedSearch: String {
        search.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearchValidEmail: Bool {
        EmailChecker(email: trimmedSearch).validate()
    }

    public init(
        attendees: Binding<[Attendee]>,
        organizer: Binding<Organizer?>,
        currentUser: UserProfile?,
        isWritable: Bool = true
    ) {
        _attendees = attendees
        _organizer = organizer
        self.currentUser = currentUser
        self.isWritable = isWritable
    }

    public var body: some View {
        List {
            Section {
                ForEach(searchedAttendees ?? uiAttendees) { attendee in
                    let addedState = addedState(of: attendee, in: uiAttendees)
                    EditableAttendeeRow(
                        attendee: attendee,
                        addedState: addedState,
                        showCheckmark: !trimmedSearch.isEmpty
                    ) {
                        addAttendee(attendee)
                    }
                    .disabled(isAttendeeLimitReached && addedState == .notAdded)
                }
                .onDelete { attendees.remove(atOffsets: $0) }
                .deleteDisabled(!isWritable || isShowingSearchResults)

                if isShowingSearchResults && !trimmedSearch.isEmpty {
                    CustomAttendeeRow(text: trimmedSearch, isValid: isSearchValidEmail, action: addCustomAttendeeFromSearch)
                        .disabled(isAttendeeLimitReached)
                }
            } header: {
                if isWritable && isAttendeeLimitReached {
                    InformationBlockView(state: .info, text: EventDraftValidator.ValidationError.tooManyAttendees.errorDescription)
                }
            }
        }
        .overlay {
            if trimmedSearch.isEmpty && attendees.isEmpty {
                ContentUnavailableView {
                    Label(CalendarResourcesStrings.attendeesEmptyStateTitle, symbol: .usersStacked)
                } description: {
                    Text(CalendarResourcesStrings.attendeesEmptyStateDescription)
                }
            }
        }
        .searchableIfWritable(
            isWritable,
            text: $search,
            isPresented: $isSearching,
            prompt: CalendarResourcesStrings.attendeesSearchPlaceholder
        )
        .task(id: trimmedSearch) {
            await searchContacts(query: trimmedSearch)
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(CalendarResourcesStrings.participantsLabel(attendees.count))
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

            withAnimation { searchedAttendees = OrderedSet(newSearchedAttendees) }
        } catch {
            guard !Task.isCancelled else { return }
            withAnimation { searchedAttendees = nil }
        }
    }

    private func addedState(of attendee: UIAttendee, in addedAttendees: OrderedSet<UIAttendee>) -> AttendeeAddedState {
        if addedAttendees.contains(attendee) {
            return .sameAttendee
        } else if addedAttendees.contains(where: { $0.email == attendee.email }) {
            return .sameEmail
        }
        return .notAdded
    }

    private func addCustomAttendeeFromSearch() {
        guard isSearchValidEmail else { return }

        let customAttendee = UIAttendee(displayName: nil, email: trimmedSearch.lowercased(), status: .needsAction)
        addAttendee(customAttendee)
    }

    private func addAttendee(_ uiAttendee: UIAttendee) {
        guard !attendees.contains(where: { $0.email.lowercased() == uiAttendee.email }) else { return }

        let isCurrentUser = uiAttendee.email == currentUser?.email.lowercased()
        var isOrganizer = false
        if let organizer {
            isOrganizer = uiAttendee.email == organizer.email.lowercased()
        } else {
            isOrganizer = isCurrentUser
        }

        let newAttendee = Attendee(
            email: uiAttendee.email,
            displayName: uiAttendee.displayName,
            status: isCurrentUser ? .accepted : .needsAction,
            role: isOrganizer ? .chair : .requested,
            isOrganizer: isOrganizer,
            responseNeeded: !isCurrentUser,
            type: .individual,
            contact: uiAttendee.contact.map { $0.sdkValue }
        )

        var newAttendees = attendees
        newAttendees.append(newAttendee)

        var newOrganizer = organizer
        var isCurrentUserAddedAsOrganizer = false
        if newOrganizer == nil {
            if isOrganizer {
                newOrganizer = Organizer(attendee: newAttendee)
            } else if let currentUserOrganizer = currentUserOrganizer(addingTo: &newAttendees) {
                newOrganizer = currentUserOrganizer
                isCurrentUserAddedAsOrganizer = true
            }
        }

        guard validator.validateAttendees(newAttendees) == nil else { return }

        withAnimation {
            attendees = newAttendees
            organizer = newOrganizer

            search = ""
            searchedAttendees = nil
            isSearching = false
        }

        if newAttendee.contact == nil {
            Task { await fillMissingContact(email: newAttendee.email) }
        }
        if isCurrentUserAddedAsOrganizer, let newOrganizer {
            Task { await fillMissingContact(email: newOrganizer.email) }
        }
    }

    private func currentUserOrganizer(addingTo attendees: inout [Attendee]) -> Organizer? {
        guard let currentUser else { return nil }

        let newOrganizer = Organizer(user: currentUser)
        if !attendees.contains(where: { $0.email.lowercased() == newOrganizer.email }) {
            attendees.insert(Attendee(organizer: newOrganizer), at: 0)
        }

        return newOrganizer
    }

    private func fillMissingContact(email: String) async {
        @InjectService var calendarSDK: CalendarCoreGraph
        guard let results = try? await calendarSDK.contactsManager.search(query: email) else { return }

        guard let contact = results.first else { return }

        if let index = attendees.firstIndex(where: { $0.email.lowercased() == email && $0.contact == nil }) {
            let attendee = attendees[index]
            attendees[index] = Attendee(
                email: attendee.email,
                displayName: attendee.displayName,
                status: attendee.status,
                role: attendee.role,
                isOrganizer: attendee.isOrganizer,
                responseNeeded: attendee.responseNeeded,
                type: attendee.type,
                contact: contact
            )
        }

        if let organizer, organizer.email.lowercased() == email, organizer.contact == nil {
            self.organizer = Organizer(email: organizer.email, displayName: organizer.displayName, contact: contact)
        }
    }
}

#Preview {
    NavigationStack {
        EditableAttendeesList(attendees: .constant([]), organizer: .constant(nil), currentUser: nil, isWritable: true)
    }
}
