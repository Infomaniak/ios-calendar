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
import CalendarEditableAttendees
import CalendarResources
import InfomaniakCore
import InfomaniakDI
import MultiplatformCalendar
import OSLog
import SwiftUI

struct AttendeesListView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts
    @Environment(\.dismiss) private var dismiss

    @State private var draft: EventDraft?
    @State private var originalDraft: EventDraft?
    @State private var currentUser: UserProfile?
    @State private var isShowingRecurrenceScope = false
    @State private var isSaving = false
    @State private var saveError: CalendarError?

    let event: UIEventDetails

    private var isEdited: Bool {
        draft != originalDraft
    }

    var body: some View {
        Group {
            if !event.canEdit {
                EditableAttendeesList(
                    attendees: .constant(event.attendees.map { $0.sdkValue }),
                    organizer: .constant(nil),
                    currentUser: nil,
                    isWritable: false
                )
            } else if let draftBinding = Binding($draft) {
                EditableAttendeesList(
                    attendees: draftBinding.attendees,
                    organizer: draftBinding.organizer,
                    currentUser: currentUser
                )
                .disabled(isSaving)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        ConfirmationButton(action: didTapSave)
                            .disabled(isSaving || !isEdited)
                            .confirmationDialog(
                                CalendarResourcesStrings.editRecurringEventAlertTitle,
                                isPresented: $isShowingRecurrenceScope,
                                titleVisibility: .visible
                            ) {
                                Button(CalendarResourcesStrings.buttonThisEvent) {
                                    saveDraft(scope: .thisOccurrence)
                                }
                                Button(CalendarResourcesStrings.buttonThisAndFollowingEvents) {
                                    saveDraft(scope: .thisAndFollowing)
                                }
                                Button(CalendarResourcesStrings.buttonAllEvents) {
                                    saveDraft(scope: .allOccurrences)
                                }
                            }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle(CalendarResourcesStrings.participantsLabel(event.attendees.count))
                    .toolbarTitleDisplayMode(.inline)
            }
        }
        .task {
            await loadDraft()
        }
        .alert(error: $saveError) {}
    }

    private func loadDraft() async {
        guard event.canEdit, draft == nil else { return }

        do {
            @InjectService var calendarSDK: CalendarCoreGraph
            let id = OccurrenceId.companion.parse(value: event.occurrenceId)

            guard let occurrence = try await calendarSDK.calendarManager.getOccurrence(occurrenceId: id),
                  let editData = try await calendarSDK.calendarManager.getEditData(occurrenceId: id) else {
                throw CalendarError.eventOccurrenceNotFound
            }

            let loadedDraft = EventDraft(event: occurrence, editData: editData)
            currentUser = calendarAccounts[Int(occurrence.accountIdValue)]?.user
            originalDraft = loadedDraft
            draft = loadedDraft
        } catch {
            Logger.view.error("Failed to load event edit data: \(error.localizedDescription)")
            saveError = (error as? CalendarError) ?? CalendarError.unknown
        }
    }

    private func didTapSave() {
        if event.isOccurrence {
            isShowingRecurrenceScope = true
        } else {
            saveDraft(scope: .thisOccurrence)
        }
    }

    private func saveDraft(scope: RecurrenceScope) {
        guard let draft else { return }

        isSaving = true
        Task {
            do {
                try await UpdateEventUseCase().execute(occurrenceId: event.occurrenceId, scope: scope, draft: draft)
                dismiss()
            } catch {
                Logger.view.error("Failed to save event attendees: \(error.localizedDescription)")
                saveError = (error as? CalendarError) ?? CalendarError.unknown
            }
            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        AttendeesListView(event: .preview)
    }
}
