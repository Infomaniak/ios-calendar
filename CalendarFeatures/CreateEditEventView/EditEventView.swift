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
import SwiftUI

struct UIDraftEvent: Sendable, Equatable {
    var calendar: UICalendar?

    var title = ""

    var allDay = false
    var startDate = Date()
    var endDate = Date().addingTimeInterval(60 * 60) // TODO: Use UserDefaults

    var isOccupied = true
    var isPrivate = false

    init() {}

    init(event: CalendarCoreUI.UIEvent) {
        self.title = event.title
    }
}

enum EditionMode {
    case create
    case edit(origin: CalendarCoreUI.UIEvent)

    var navigationTitle: String {
        switch self {
        case .create:
            return "Create Event"
        case .edit:
            return "Edit Event"
        }
    }
}

public struct EditEventView: View {
    @State private var draft: UIDraftEvent

    private let editionMode: EditionMode

    private var datePickerComponents: DatePickerComponents {
        draft.allDay ? .date : [.date, .hourAndMinute]
    }

    public init(event: CalendarCoreUI.UIEvent? = nil) {
        if let event {
            _draft = State(wrappedValue: UIDraftEvent(event: event))
            editionMode = .edit(origin: event)
        } else {
            _draft = State(wrappedValue: UIDraftEvent())
            editionMode = .create
        }
    }

    public var body: some View {
        Form {
            Section {
                TextField("Title", text: $draft.title)
            }

            Section {
                Toggle("Toute la journée", isOn: $draft.allDay)
                DatePicker("Début", selection: $draft.startDate, displayedComponents: datePickerComponents)
                    .datePickerStyle(.compact)
                DatePicker("Fin", selection: $draft.endDate, displayedComponents: datePickerComponents)
                    .datePickerStyle(.compact)
            }

            Section {
                // Occupés
                // Private
            }

            if draft.calendar != nil {
                Section {
                    Picker(selection: $draft.calendar) {
                        Text("ToDo")
                    } label: {
                        Text("Calendrier")
                    }
                }
            }
        }
        .navigationTitle(Text(editionMode.navigationTitle))
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    // TODO: Confirm
                } label: {
                    Text("Valider")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .closeToolbarItem {
            // TODO: Cancel
        }
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                EditEventView()
            }
            .interactiveDismissDisabled()
        }
}
