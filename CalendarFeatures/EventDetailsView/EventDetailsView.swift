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

    private let event: CalendarCoreUI.UIEvent

    private var uniqueAttendees: [UIAttendee] {
        var seenEmails = Set<String>()

        return event.attendees.filter { attendee in
            seenEmails.insert(attendee.email).inserted
        }
    }

    private var hasLocationSection: Bool {
        event.kMeetLink != nil || event.location != nil
    }

    public init(event: CalendarCoreUI.UIEvent) {
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
                                icon: CalendarResourcesAsset.Images.productKmeet.swiftUIImage,
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

                if let classification = event.classification, let icon = classification.icon,
                   let text = classification.text {
                    Section {
                        // TODO: Add another row for free/busy status when available
                        StatusRow(text: text, icon: icon)
                    }
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
                        Button { /* Does nothing yet */ } label: {
                            Label(CalendarResourcesStrings.editEventTitle, image: CalendarResourcesAsset.Images.pen)
                        }
                        .disabled(true)
                    }

                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            isShowingDeleteConfirmationDialog = true
                        } label: {
                            if isDeletingEvent {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Label(CalendarResourcesStrings.buttonDeleteEvent, image: CalendarResourcesAsset.Images.trash)
                            }
                        }
                        .disabled(isDeletingEvent || !event.canEdit)
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
                                    Text(CalendarResourcesStrings.buttonDeleteAllEvents)
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
            .navigationBarTitleDisplayMode(.inline)
            .listSectionSpacing(IKPadding.large)
            .contentMargins(.top, 0, for: .scrollContent)
            .safeAreaInset(edge: .bottom) {
                if selectedStatus != nil {
                    HStack(spacing: IKPadding.medium) {
                        ForEach([UIParticipationStatus.accepted, .declined, .tentative], id: \.self) { answer in
                            AnswerButton(
                                answer: answer,
                                isSelected: selectedStatus == answer
                            ) {
                                // TODO: Update the event's participation status when the user selects an answer
                                selectedStatus = answer
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
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
    EventDetailsView(event: CalendarCoreUI.UIEvent.preview)
}
