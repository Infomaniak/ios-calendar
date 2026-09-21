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
import DesignSystem
import ESDSFoundation
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI
import UIKit

public enum EditionMode {
    case new
    case editEvent(origin: CalendarCoreUI.UIEvent, calendar: UICalendar)
    case editDraft(draft: EventDraft)

    var navigationTitle: String {
        switch self {
        case .new:
            return CalendarResourcesStrings.createEventTitle
        case .editEvent, .editDraft:
            return CalendarResourcesStrings.editEventTitle
        }
    }
}

public struct EventFormView: View {
    private enum DatePickerId {
        case start
        case end
    }

    @Environment(\.esdsTheme) private var theme

    @State private var availableCalendars = [UICalendar]()

    @State private var draft: EventDraft
    @State private var expandedDatePickerId: DatePickerId?
    @State private var isNavigatingToAttendeesList = false

    @FocusState private var isTitleFocused: Bool

    private let editionMode: EditionMode
    private let completion: () -> Void
    private let validator = EventDraftValidator()

    private var validationErrors: Set<EventDraftValidator.ValidationError> {
        validator.validate(draft)
    }

    public init(editionMode: EditionMode, completion: @escaping () -> Void = {}) {
        switch editionMode {
        case .new:
            _draft = State(wrappedValue: EventDraft.empty())
        case .editEvent(let origin, let calendar):
            _draft = State(wrappedValue: EventDraft.fromEvent(origin, calendar: calendar))
        case .editDraft(let draft):
            _draft = State(wrappedValue: draft)
        }

        self.editionMode = editionMode
        self.completion = completion
    }

    public var body: some View {
        Form {
            Section {
                TextField(CalendarResourcesStrings.titleLabel, text: $draft.title)
                    .focused($isTitleFocused)
            } footer: {
                if validationErrors.contains(.titleTooLong) {
                    HStack {
                        Text(EventDraftValidator.ValidationError.titleTooLong.errorDescription)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(EventDraftValidator.maximumTitleCharacterCount - draft.title.count, format: .number)
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(theme.color.contentFeedbackError)
                }
            }

            Section {
                Toggle(CalendarResourcesStrings.allDayLabel, isOn: $draft.allDay)

                ExpandableDatePicker(
                    date: $draft.startDate,
                    timeZone: Binding(
                        get: { draft.startTimeZone ?? .current },
                        set: { draft.startTimeZone = $0 }
                    ),
                    expandedPickerId: $expandedDatePickerId,
                    id: .start,
                    label: CalendarResourcesStrings.startLabel,
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
                    timeZone: Binding(
                        get: { draft.endTimeZone ?? .current },
                        set: { draft.endTimeZone = $0 }
                    ),
                    expandedPickerId: $expandedDatePickerId,
                    id: .end,
                    label: CalendarResourcesStrings.endLabel,
                    canSelectHour: !draft.allDay,
                    range: draft.startDate ... Date.distantFuture
                )
            }

            Section {
                Button {
                    isNavigatingToAttendeesList = true
                } label: {
                    EventAttendeesCell(attendees: draft.attendees.map { UIAttendee(attendee: $0) })
                }
                .navigationDestination(isPresented: $isNavigatingToAttendeesList) {
                    Text(CalendarResourcesStrings.attendeesNotEditableMessage)
                }
            }

            Section {
                Toggle(isOn: $draft.isOccupied) {
                    Label {
                        Text(CalendarResourcesStrings.occupiedLabel)
                    } icon: {
                        CalendarResourcesAsset.Images.briefcase.swiftUIImage
                    }
                    .labelStyle(.formLabel)
                }
                Toggle(isOn: $draft.isPrivate) {
                    Label {
                        Text(CalendarResourcesStrings.privateLabel)
                    } icon: {
                        BouncyLock(isUnlocked: !draft.isPrivate)
                    }
                    .labelStyle(.formLabel)
                }
            }

            if !availableCalendars.isEmpty {
                Section {
                    LabeledContent(CalendarResourcesStrings.calendarsMenuSectionTitle) {
                        CalendarPicker(calendarId: $draft.calendarId, calendars: availableCalendars)
                    }
                }
            }
        }
        .onAppear {
            focusTitleIfNecessary()
        }
        .task {
            await observeCalendars()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Text(editionMode.navigationTitle))
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        try? await CreateEventUseCase().execute(draft: draft)
                        completion()
                    }
                } label: {
                    Label(CalendarResourcesStrings.buttonConfirm, image: CalendarResourcesAsset.Images.check)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!validationErrors.isEmpty)
            }
        }
        .closeToolbarItem(completion)
    }

    private func focusTitleIfNecessary() {
        if case .new = editionMode {
            isTitleFocused = true
        }
    }

    private func shiftEndTimeZoneIfNecessary(oldValue: TimeZone?, newValue: TimeZone?) {
        if oldValue == draft.endTimeZone {
            draft.endTimeZone = newValue
        }
    }

    private func shiftEndDateIfNecessary(oldValue: Date, newValue: Date) {
        guard newValue >= draft.endDate else { return }

        let previousDuration = draft.endDate.timeIntervalSince(oldValue)
        draft.endDate = newValue.addingTimeInterval(previousDuration)
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            availableCalendars = calendars.map { UICalendar(calendar: $0) }.filter { $0.accessLevel.canWrite }

            if draft.calendarId == nil {
                draft.calendarId = availableCalendars.first?.id
            }
        }
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                EventFormView(editionMode: .new) {}
            }
            .interactiveDismissDisabled()
        }
}
