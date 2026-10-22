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
import CalendarEventFormView
import CalendarResources
import DesignSystem
import ESDSFoundation
import ESDSSymbols
import InfomaniakDI
import MultiplatformCalendar
import OSLog
import SwiftUI

public struct EventDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var alarms: [UIEventAlarm]
    @State private var selectedStatus: UIParticipationStatus?
    @State private var showNavigationTitle = false
    @State private var isNavigatingToAttendeesList = false

    @State private var isDeletingEvent = false
    @State private var isShowingDeleteConfirmationDialog = false
    @State private var isShowingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var isLoadingEdit = false
    @State private var editData: EventEditData?
    @State private var isShowingEditError = false
    @State private var editErrorMessage = ""
    @State private var isShowingReplyError = false
    @State private var replyErrorMessage = ""

    private let event: UIEventDetails

    private var uniqueAttendees: [UIAttendee] {
        var seenEmails = Set<String>()

        return event.attendees.compactMap { attendee in
            guard seenEmails.insert(attendee.email).inserted else { return nil }

            guard let selectedStatus, attendee.email == event.user?.email else { return attendee }
            return UIAttendee(
                displayName: attendee.displayName,
                email: attendee.email,
                status: selectedStatus,
                isOrganizer: attendee.isOrganizer,
                contact: attendee.contact
            )
        }
    }

    private var hasLocationSection: Bool {
        event.kMeetLink != nil || event.location != nil
    }

    public init(event: UIEventDetails) {
        self.event = event
        _alarms = State(initialValue: event.alarms)
        _selectedStatus = State(initialValue: event.user?.status)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: IKPadding.small) {
                        EventTitleRow(
                            title: event.displayTitle,
                            eventColor: event.colors.sourceColor
                        )
                        .onScrollVisibilityChange(threshold: 0.5) { isVisible in
                            // onScrollVisibilityChange is broken for versions before iOS 27.0
                            if #available(iOS 27.0, *) {
                                withAnimation {
                                    showNavigationTitle = !isVisible
                                }
                            }
                        }

                        DayRow(event: event)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if !uniqueAttendees.isEmpty {
                    Section {
                        Button {
                            isNavigatingToAttendeesList = true
                        } label: {
                            EventAttendeesCell(attendees: uniqueAttendees)
                        }
                        .navigationDestination(isPresented: $isNavigatingToAttendeesList) {
                            AttendeesListView(attendees: uniqueAttendees)
                        }
                    }
                }

                if hasLocationSection {
                    Section {
                        if let kMeetLink = event.kMeetLink {
                            OpenLinkRow(
                                title: CalendarResourcesStrings.participateKMeetTitle,
                                buttonTitle: CalendarResourcesStrings.buttonJoin,
                                icon: .productKmeet,
                                linkURL: kMeetLink,
                                showLink: false
                            )
                        }

                        if let address = event.location {
                            LocationRow(address: address)
                        }

                        // TODO: Show meeting room information when available
                    }
                }

                if let description = event.description, !description.isEmpty {
                    Section {
                        DescriptionRow(description: description)
                    }

                    // TODO: Show attachments when available using FileTypeProvider
                }

                if !alarms.isEmpty {
                    Section {
                        AlertsSectionView(alarms: $alarms)
                    }
                }

                Section {
                    // TODO: Add another row for free/busy status when available
                    StatusRow(text: event.classification.text, icon: event.classification.icon)
                }

                Section {
                    EventCalendarRow(event: event)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .closeToolbarItem(dismiss: dismiss)
            .toolbar {
                if #available(iOS 27.0, *) {
                    ToolbarItem(placement: .principal) {
                        Text(event.displayTitle)
                            .opacity(showNavigationTitle ? 1 : 0)
                    }
                }

                if event.canEdit {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            loadEditData()
                        } label: {
                            Label(CalendarResourcesStrings.editEventTitle, symbol: .pen)
                        }
                        .disabled(isLoadingEdit || isDeletingEvent)
                    }

                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            isShowingDeleteConfirmationDialog = true
                        } label: {
                            Label(CalendarResourcesStrings.buttonDeleteEvent, symbol: .trash)
                        }
                        .disabled(isDeletingEvent)
                        .confirmationDialog(
                            !event.isOccurrence
                                ? CalendarResourcesStrings.deleteEventAlertTitle
                                : CalendarResourcesStrings.deleteRecurringEventAlertTitle,
                            isPresented: $isShowingDeleteConfirmationDialog,
                            titleVisibility: .visible
                        ) {
                            Button(role: .destructive) {
                                deleteEvent(scope: .thisOccurrence)
                            } label: {
                                Text(CalendarResourcesStrings.buttonDeleteEvent)
                            }

                            if event.isOccurrence {
                                Button(role: .destructive) {
                                    deleteEvent(scope: .thisAndFollowing)
                                } label: {
                                    Text(CalendarResourcesStrings.buttonDeleteThisAndFollowingEvents)
                                }

                                Button(role: .destructive) {
                                    deleteEvent(scope: .allOccurrences)
                                } label: {
                                    Text(CalendarResourcesStrings.buttonAllEvents)
                                }
                            }
                        }
                    }
                }
            }
            .alert(CalendarResourcesStrings.deleteEventErrorTitle, isPresented: $isShowingDeleteError) {
                Button(CalendarResourcesStrings.buttonConfirm) {}
            } message: {
                Text(deleteErrorMessage)
            }
            .alert(CalendarResourcesStrings.editEventTitle, isPresented: $isShowingEditError) {
                Button(CalendarResourcesStrings.buttonConfirm) {}
            } message: {
                Text(editErrorMessage)
            }
            .alert(CalendarResourcesStrings.replyEventErrorTitle, isPresented: $isShowingReplyError) {
                Button(CalendarResourcesStrings.buttonConfirm) {}
            } message: {
                Text(replyErrorMessage)
            }
            .navigationDestination(item: $editData) { editData in
                EventFormView(
                    editionMode: .editDraft(
                        draft: EventDraft.fromEvent(event, editData: editData),
                        editingEvent: event
                    )
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .listSectionSpacing(IKPadding.large)
            .contentMargins(.top, 0, for: .scrollContent)
            .safeAreaInset(edge: .bottom) {
                if selectedStatus != nil {
                    HStack(spacing: IKPadding.medium) {
                        ForEach([UIParticipationStatus.accepted, .declined, .tentative], id: \.self) { answer in
                            AnswerButton(
                                shouldShowDialog: event.isOccurrence,
                                answer: answer,
                                isSelected: selectedStatus == answer
                            ) { scope in
                                updateParticipationStatus(to: answer, scope: scope)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private func loadEditData() {
        isLoadingEdit = true
        Task {
            do {
                @InjectService var calendarSDK: CalendarCoreGraph
                let id = OccurrenceId.companion.parse(value: event.occurrenceId)
                guard let data = try await calendarSDK.calendarManager.getEditData(occurrenceId: id) else {
                    throw CalendarError.eventOccurrenceNotFound
                }
                editData = data
            } catch {
                Logger.view.error("Failed to load event edit data: \(error.localizedDescription)")
                editErrorMessage = error.localizedDescription
                isShowingEditError = true
            }
            isLoadingEdit = false
        }
    }

    private func updateParticipationStatus(to status: UIParticipationStatus, scope: RecurrenceScope) {
        guard let reply = status.reply else { return }

        Task {
            do {
                try await UpdateParticipationStatusUseCase().execute(
                    reply: reply,
                    occurrenceId: event.occurrenceId,
                    scope: scope
                )
                selectedStatus = status
            } catch {
                Logger.view.error("Failed to update participation status: \(error.localizedDescription)")
                replyErrorMessage = error.localizedDescription
                isShowingReplyError = true
            }
        }
    }

    private func deleteEvent(scope: RecurrenceScope) {
        isDeletingEvent = true

        Task {
            do {
                try await DeleteEventUseCase().execute(occurrenceId: event.occurrenceId, scope: scope)
                dismiss()
            } catch {
                Logger.view.error("Failed to delete event: \(error.localizedDescription)")
                deleteErrorMessage = error.localizedDescription
                isShowingDeleteError = true
            }
            isDeletingEvent = false
        }
    }
}

#Preview {
    EventDetailsView(event: UIEventDetails.preview)
}
