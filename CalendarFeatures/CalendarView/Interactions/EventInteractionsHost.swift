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
import MultiplatformCalendar
import SwiftUI

extension View {
    /// Provides the `EventInteractionModel` and presents what its interactions need.
    ///
    /// Sheets and dialogs live here rather than next to their trigger: context menus and drop targets are gone by the time
    /// they are presented.
    func eventInteractionsHost() -> some View {
        modifier(EventInteractionsHostModifier())
    }
}

private struct EventInteractionsHostModifier: ViewModifier {
    @Environment(\.calendar) private var calendar
    @Environment(\.undoManager) private var undoManager

    @State private var interaction = EventInteractionModel()

    func body(content: Content) -> some View {
        @Bindable var interaction = interaction

        content
            .environment(interaction)
            .task {
                await interaction.observeCalendars()
            }
            .onChange(of: undoManager, initial: true) { _, newUndoManager in
                interaction.undoManager = newUndoManager
            }
            .sheet(item: $interaction.formRoute, onDismiss: interaction.cancelCreation) { route in
                EventFormRouteView(route: route)
            }
            .confirmationDialog(
                CalendarResourcesStrings.editRecurringEventAlertTitle,
                isPresented: isPresented($interaction.pendingMove, onDismiss: interaction.cancelPendingMove),
                titleVisibility: .visible,
                presenting: interaction.pendingMove
            ) { pendingMove in
                Button(CalendarResourcesStrings.buttonThisEvent) {
                    interaction.commitMove(pendingMove, scope: .thisOccurrence, calendar: calendar)
                }
                Button(CalendarResourcesStrings.buttonThisAndFollowingEvents) {
                    interaction.commitMove(pendingMove, scope: .thisAndFollowing, calendar: calendar)
                }
                Button(CalendarResourcesStrings.buttonAllEvents) {
                    interaction.commitMove(pendingMove, scope: .allOccurrences, calendar: calendar)
                }
            }
            .confirmationDialog(
                interaction.pendingDeletion?.isRecurring == true
                    ? CalendarResourcesStrings.deleteRecurringEventAlertTitle
                    : CalendarResourcesStrings.deleteEventAlertTitle,
                isPresented: isPresented($interaction.pendingDeletion),
                titleVisibility: .visible,
                presenting: interaction.pendingDeletion
            ) { event in
                Button(CalendarResourcesStrings.buttonDeleteEvent, role: .destructive) {
                    interaction.delete(event, scope: .thisOccurrence)
                }
                if event.isRecurring {
                    Button(CalendarResourcesStrings.buttonThisAndFollowingEvents, role: .destructive) {
                        interaction.delete(event, scope: .thisAndFollowing)
                    }
                    Button(CalendarResourcesStrings.buttonAllEvents, role: .destructive) {
                        interaction.delete(event, scope: .allOccurrences)
                    }
                }
            }
            .confirmationDialog(
                CalendarResourcesStrings.replyRecurringEventAlertTitle,
                isPresented: isPresented($interaction.pendingReply),
                titleVisibility: .visible,
                presenting: interaction.pendingReply
            ) { pendingReply in
                Button(CalendarResourcesStrings.buttonThisEvent) {
                    interaction.reply(pendingReply.status, to: pendingReply.event, scope: .thisOccurrence)
                }
                Button(CalendarResourcesStrings.buttonAllEvents) {
                    interaction.reply(pendingReply.status, to: pendingReply.event, scope: .allOccurrences)
                }
            }
            .alert(
                interaction.alert?.title ?? "",
                isPresented: isPresented($interaction.alert),
                presenting: interaction.alert
            ) { _ in
                Button(CalendarResourcesStrings.buttonConfirm) {}
            } message: { alert in
                Text(alert.message)
            }
            .sensoryFeedback(.selection, trigger: interaction.placeholder?.start) { oldValue, newValue in
                oldValue != nil && newValue != nil
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: interaction.placeholder == nil) { _, isHidden in
                !isHidden
            }
    }

    private func isPresented<Item>(_ item: Binding<Item?>, onDismiss: (() -> Void)? = nil) -> Binding<Bool> {
        return Binding {
            item.wrappedValue != nil
        } set: { isPresented in
            guard !isPresented, item.wrappedValue != nil else { return }
            item.wrappedValue = nil
            onDismiss?()
        }
    }
}

private struct EventFormRouteView: View {
    @Environment(\.dismiss) private var dismiss

    let route: EventFormRoute

    var body: some View {
        NavigationStack {
            switch route.mode {
            case .create(let draft):
                EventFormView(editionMode: .prefilled(draft: draft))
            case .edit(let draft, let event):
                EventFormView(editionMode: .editDraft(draft: draft, editingEvent: event))
                    .closeToolbarItem(dismiss: dismiss)
            }
        }
    }
}
