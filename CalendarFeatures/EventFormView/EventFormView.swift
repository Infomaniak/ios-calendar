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
import SwiftUI

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

    @State private var viewModel: EventFormViewModel
    @State private var expandedDatePickerId: DatePickerId?
    @State private var timeZonePickerId: DatePickerId?
    @State private var isNavigatingToAttendeesList = false

    @State private var hasFocusedKeyboardOnce = false
    @FocusState private var isTitleFocused: Bool

    private let editionMode: EditionMode
    private let completion: () -> Void

    public init(editionMode: EditionMode, completion: @escaping () -> Void = {}) {
        _viewModel = State(wrappedValue: EventFormViewModel(editionMode: editionMode))
        self.editionMode = editionMode
        self.completion = completion
    }

    public var body: some View {
        Form {
            Section {
                TextField(CalendarResourcesStrings.eventTitle, text: $viewModel.draft.title)
                    .focused($isTitleFocused)
            } footer: {
                if viewModel.validationErrors.contains(.titleTooLong) {
                    HStack {
                        Text(EventDraftValidator.ValidationError.titleTooLong.errorDescription)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(EventDraftValidator.maximumTitleCharacterCount - viewModel.draft.title.count, format: .number)
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(theme.color.contentFeedbackError)
                }
            }

            Section {
                Toggle(CalendarResourcesStrings.allDayLabel, isOn: $viewModel.draft.allDay)

                ExpandableDatePicker(
                    date: $viewModel.draft.startDate,
                    expandedPickerId: $expandedDatePickerId,
                    timeZonePickerId: $timeZonePickerId,
                    timeZone: viewModel.draft.startTimeZone ?? .current,
                    id: .start,
                    label: CalendarResourcesStrings.startLabel,
                    canSelectHour: !viewModel.draft.allDay
                )
                .onChange(of: viewModel.draft.startTimeZone) { oldValue, newValue in
                    viewModel.shiftEndTimeZoneIfNecessary(oldValue: oldValue, newValue: newValue)
                }
                .onChange(of: viewModel.draft.startDate) { oldValue, newValue in
                    viewModel.shiftEndDateIfNecessary(oldValue: oldValue, newValue: newValue)
                }

                ExpandableDatePicker(
                    date: $viewModel.draft.endDate,
                    expandedPickerId: $expandedDatePickerId,
                    timeZonePickerId: $timeZonePickerId,
                    timeZone: viewModel.draft.endTimeZone ?? .current,
                    id: .end,
                    label: CalendarResourcesStrings.endLabel,
                    canSelectHour: !viewModel.draft.allDay,
                    range: viewModel.draft.startDate ... Date.distantFuture
                )
            }

            Section {
                Button {
                    isNavigatingToAttendeesList = true
                } label: {
                    EventAttendeesCell(attendees: viewModel.draft.attendees.map { UIAttendee(attendee: $0) })
                }
                .navigationDestination(isPresented: $isNavigatingToAttendeesList) {
                    Text(CalendarResourcesStrings.attendeesNotEditableMessage)
                }
            }

            Section {
                Toggle(isOn: $viewModel.draft.isOccupied) {
                    Label {
                        Text(CalendarResourcesStrings.occupiedLabel)
                    } icon: {
                        CalendarResourcesAsset.Images.briefcase.swiftUIImage
                    }
                    .labelStyle(.formLabel)
                }
                Toggle(isOn: $viewModel.draft.isPrivate) {
                    Label {
                        Text(CalendarResourcesStrings.privateLabel)
                    } icon: {
                        BouncyLock(isUnlocked: !viewModel.draft.isPrivate)
                    }
                    .labelStyle(.formLabel)
                }
            }

            if !viewModel.availableCalendars.isEmpty {
                Section {
                    LabeledContent(CalendarResourcesStrings.calendarsMenuSectionTitle) {
                        CalendarPicker(calendarId: $viewModel.draft.calendarId, calendars: viewModel.availableCalendars)
                    }
                }
            }
        }
        .navigationDestination(item: $timeZonePickerId) { pickerId in
            switch pickerId {
            case .start:
                TimeZoneListView(
                    timeZone: Binding(
                        get: { viewModel.draft.startTimeZone ?? .current },
                        set: { viewModel.draft.startTimeZone = $0 }
                    ),
                    referenceDate: viewModel.draft.startDate
                )
            case .end:
                TimeZoneListView(
                    timeZone: Binding(
                        get: { viewModel.draft.endTimeZone ?? .current },
                        set: { viewModel.draft.endTimeZone = $0 }
                    ),
                    referenceDate: viewModel.draft.endDate
                )
            }
        }
        .onAppear {
            focusTitleIfNecessary()
        }
        .task {
            await viewModel.observeCalendars()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Text(editionMode.navigationTitle))
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        try? await viewModel.createEvent()
                        completion()
                    }
                } label: {
                    Label(CalendarResourcesStrings.buttonConfirm, image: CalendarResourcesAsset.Images.check)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.validationErrors.isEmpty)
            }
        }
        .closeToolbarItem(completion)
        .interactiveDismissDisabled(viewModel.isEdited)
    }

    private func focusTitleIfNecessary() {
        guard case .new = editionMode, !hasFocusedKeyboardOnce else {
            return
        }

        hasFocusedKeyboardOnce = true
        withAnimation {
            isTitleFocused = true
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
