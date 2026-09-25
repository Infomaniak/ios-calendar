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
import MultiplatformCalendar
import OSLog
import SwiftUI

public enum EditionMode {
    case new
    case editDraft(draft: EventDraft)

    var navigationTitle: String {
        switch self {
        case .new:
            return CalendarResourcesStrings.createEventTitle
        case .editDraft:
            return CalendarResourcesStrings.editEventTitle
        }
    }
}

public struct EventFormView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: EventFormViewModel
    @State private var expandedDatePickerId: EventFormViewModel.DatePickerId?
    @State private var timeZonePickerId: EventFormViewModel.DatePickerId?
    @State private var isNavigatingToAttendeesList = false
    @State private var isShowingRecurrenceScope = false
    @State private var isSaving = false
    @State private var saveErrorMessage: CalendarError?

    @State private var hasFocusedKeyboardOnce = false
    @FocusState private var isTitleFocused: Bool

    private let editionMode: EditionMode
    private let editingEvent: CalendarCoreUI.UIEvent?
    private let completion: () -> Void
    private let onSaved: () -> Void

    public init(
        editionMode: EditionMode,
        editingEvent: CalendarCoreUI.UIEvent? = nil,
        completion: @escaping () -> Void = {},
        onSaved: (() -> Void)? = nil
    ) {
        _viewModel = State(wrappedValue: EventFormViewModel(editionMode: editionMode))
        self.editionMode = editionMode
        self.editingEvent = editingEvent
        self.completion = completion
        self.onSaved = onSaved ?? completion
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
                    date: Binding(
                        get: { viewModel.draft.startDate },
                        set: { viewModel.updateStartDate($0) }
                    ),
                    expandedPickerId: $expandedDatePickerId,
                    timeZonePickerId: $timeZonePickerId,
                    timeZone: viewModel.draft.startTimeZone ?? .current,
                    id: .start,
                    label: CalendarResourcesStrings.startLabel,
                    canSelectHour: !viewModel.draft.allDay
                )

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
                        set: { viewModel.updateTimeZone($0, for: .start, calendar: calendar) }
                    ),
                    referenceDate: viewModel.draft.startDate
                )
            case .end:
                TimeZoneListView(
                    timeZone: Binding(
                        get: { viewModel.draft.endTimeZone ?? .current },
                        set: { viewModel.updateTimeZone($0, for: .end, calendar: calendar) }
                    ),
                    referenceDate: viewModel.draft.endDate
                )
            }
        }
        .disabled(isSaving)
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
            if editingEvent == nil {
                CloseToolbarItem(action: completion)
            }

            ToolbarItem(placement: .confirmationAction) {
                ConfirmationButton(action: didTapSave)
                    .disabled(isSaving || !viewModel.validationErrors.isEmpty || !viewModel.isEdited)
                    .confirmationDialog(
                        CalendarResourcesStrings.editRecurringEventAlertTitle,
                        isPresented: $isShowingRecurrenceScope,
                        titleVisibility: .visible
                    ) {
                        Button(CalendarResourcesStrings.buttonEditThisEvent) {
                            saveEvent(scope: .thisOccurrence)
                        }
                        Button(CalendarResourcesStrings.buttonDeleteThisAndFollowingEvents) {
                            saveEvent(scope: .thisAndFollowing)
                        }
                        Button(CalendarResourcesStrings.buttonDeleteAllEvents) {
                            saveEvent(scope: .allOccurrences)
                        }
                    }
            }
        }
        .alert(error: $saveErrorMessage) {}
        .interactiveDismissDisabled(viewModel.isEdited)
    }

    private func didTapSave() {
        if editingEvent?.isOccurrence == true {
            isShowingRecurrenceScope = true
        } else {
            saveEvent(scope: .thisOccurrence)
        }
    }

    private func saveEvent(scope: RecurrenceScope) {
        isSaving = true
        Task {
            do {
                try await viewModel.saveEvent(editingOccurrenceId: editingEvent?.occurrenceId, scope: scope)

                dismiss()
            } catch {
                saveErrorMessage = (error as? CalendarError) ?? CalendarError.unknown
            }
            isSaving = false
        }
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
