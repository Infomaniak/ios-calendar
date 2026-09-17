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
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI
import UIKit

public enum EditionMode {
    case new
    case editEvent(origin: CalendarCoreUI.UIEvent, calendar: UICalendar)
    case editDraft(draft: UIDraftEvent)

    var navigationTitle: String {
        switch self {
        case .new:
            return "!Create Event"
        case .editEvent, .editDraft:
            return "!Edit Event"
        }
    }
}

public struct EditEventView: View {
    private enum DatePickerId {
        case start
        case end
    }

    @State private var availableCalendars = [UICalendar]()

    @State private var draft: UIDraftEvent
    @State private var expandedDatePickerId: DatePickerId?
    @State private var isNavigatingToAttendeesList = false

    @FocusState private var isTitleFocused: Bool

    private let editionMode: EditionMode
    private let completion: () -> Void

    private var datePickerComponents: DatePickerComponents {
        draft.allDay ? .date : [.date, .hourAndMinute]
    }

    public init(editionMode: EditionMode, completion: @escaping () -> Void = {}) {
        switch editionMode {
        case .new:
            _draft = State(wrappedValue: UIDraftEvent.empty())
        case .editEvent(let origin, let calendar):
            _draft = State(wrappedValue: UIDraftEvent.fromEvent(origin, calendar: calendar))
        case .editDraft(let draft):
            _draft = State(wrappedValue: draft)
        }

        self.editionMode = editionMode
        self.completion = completion
    }

    public var body: some View {
        Form {
            Section {
                TextField("!Title", text: $draft.title)
                    .focused($isTitleFocused)
            }

            Section {
                Toggle("!Toute la journée", isOn: $draft.allDay)

                ExpandableDatePicker(
                    date: $draft.startDate,
                    timeZone: $draft.startTimeZone,
                    expandedPickerId: $expandedDatePickerId,
                    id: .start,
                    label: "!Début",
                    canSelectHour: !draft.allDay
                )
                .onChange(of: draft.startTimeZone) { oldValue, newValue in
                    shiftEndTimeZoneIfNecessary(oldValue: oldValue, newValue: newValue)
                }
                .onChange(of: draft.startDate) { oldValue, newValue in
                    shiftEndDateIfNecessary(oldValue: oldValue, newValue: newValue)
                }

                ExpandableDatePicker(
                    date: $draft.endDate,
                    timeZone: $draft.endTimeZone,
                    expandedPickerId: $expandedDatePickerId,
                    id: .end,
                    label: "!Fin",
                    canSelectHour: !draft.allDay,
                    range: draft.startDate ... Date.distantFuture
                )
            }

            Section {
                Button {
                    isNavigatingToAttendeesList = true
                } label: {
                    EventAttendeesCell(attendees: draft.attendees)
                }
                .navigationDestination(isPresented: $isNavigatingToAttendeesList) {
                    Text("Not editable yet.")
                }
            }

            Section {
                Toggle(isOn: $draft.isOccupied) {
                    Label("!Occupé(e)", image: CalendarResourcesAsset.Images.briefcase)
                        .labelStyle(.formLabel)
                }
                Toggle(isOn: $draft.isPrivate) {
                    Label {
                        Text("!Privé")
                    } icon: {
                        BouncyLock(isUnlocked: !draft.isPrivate)
                    }
                    .labelStyle(.formLabel)
                }
            }

            Section {
                Picker(selection: $draft.calendar) {
                    ForEach(availableCalendars) { calendar in
                        CalendarCell(calendar: calendar)
                            .tag(calendar)
                    }
                } label: {
                    Text("!Calendriers")
                }
            }
        }
        .onAppear {
            focusTitleIfNecessary()
        }
        .task {
            await observeCalendars()
        }
        .navigationTitle(Text(editionMode.navigationTitle))
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    // TODO: Confirm
                    completion()
                } label: {
                    Label("!Confirmer", image: CalendarResourcesAsset.Images.check)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .closeToolbarItem(completion)
    }

    private func focusTitleIfNecessary() {
        if case .new = editionMode {
            isTitleFocused = true
        }
    }

    private func shiftEndTimeZoneIfNecessary(oldValue: TimeZone, newValue: TimeZone) {
        if oldValue == draft.endTimeZone {
            draft.endTimeZone = newValue
        }
    }

    private func shiftEndDateIfNecessary(oldValue: Date, newValue: Date) {
        let startDate = newValue.addingTimeInterval(Double(draft.startTimeZone.secondsFromGMT(for: newValue)))
        let endDate = draft.endDate.addingTimeInterval(Double(draft.endTimeZone.secondsFromGMT(for: draft.endDate)))

        if startDate >= endDate {
            let previousDuration = draft.endDate.timeIntervalSince(oldValue)
            draft.endDate = newValue.addingTimeInterval(previousDuration)
        }
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            availableCalendars = calendars.map { UICalendar(calendar: $0) }

            if draft.calendar == nil {
                draft.calendar = availableCalendars.first
            }
        }
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                EditEventView(editionMode: .new) {}
            }
            .interactiveDismissDisabled()
        }
}
