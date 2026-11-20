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
import CalendarEventDetailsView
import CalendarResources
import ESDSSymbols
import SwiftUI

struct EventQuickActions: OptionSet {
    let rawValue: Int

    /// Context menu on long press (right-click with a pointer).
    static let menu = EventQuickActions(rawValue: 1 << 0)
    /// Native drag, to move the event in the calendar or drop it in another app.
    static let drag = EventQuickActions(rawValue: 1 << 1)

    static let all: EventQuickActions = [.menu, .drag]
}

extension View {
    func eventQuickActions(_ actions: EventQuickActions, event: UIEventSummary) -> some View {
        modifier(EventQuickActionsModifier(event: event, actions: actions))
    }
}

private struct EventQuickActionsModifier: ViewModifier {
    @Environment(EventInteractionModel.self) private var interaction

    let event: UIEventSummary
    let actions: EventQuickActions

    private var isMoving: Bool {
        return interaction.movingOccurrenceId == event.occurrenceId
    }

    func body(content: Content) -> some View {
        content
            .opacity(isMoving ? 0.4 : 1)
            .modifier(EventDragSourceModifier(event: event, isEnabled: actions.contains(.drag)))
            .modifier(EventContextMenuModifier(event: event, isEnabled: actions.contains(.menu)))
    }
}

private struct EventDragSourceModifier: ViewModifier {
    let event: UIEventSummary
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .draggable(EventDragTracker.begin(event)) {
                    EventPreviewCard(event: event, style: .drag)
                }
        } else {
            content
        }
    }
}

private struct EventContextMenuModifier: ViewModifier {
    @Environment(\.calendar) private var calendar

    let event: UIEventSummary
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content
                // A dedicated preview: lifting the cell itself is misaligned in the timeline and planning layouts.
                .contextMenu {
                    EventQuickActionsMenu(event: event)
                } preview: {
                    EventPreviewCard(event: event, style: .contextMenu)
                        .environment(\.calendar, calendar)
                }
        } else {
            content
        }
    }
}

struct EventQuickActionsMenu: View {
    @Environment(\.calendarAccounts) private var calendarAccounts
    @Environment(EventInteractionModel.self) private var interaction
    @Environment(MainViewState.self) private var mainViewState

    let event: UIEventSummary

    private var transferItem: EventTransferItem {
        return EventTransferItem(event: event)
    }

    var body: some View {
        Section {
            Button {
                mainViewState.presentedEvent = event
            } label: {
                Label(CalendarResourcesStrings.openTitle, symbol: .eye)
            }

            if event.canEdit {
                Button {
                    interaction.edit(event, calendarAccounts: calendarAccounts)
                } label: {
                    Label(CalendarResourcesStrings.editEventTitle, symbol: .pen)
                }
            }

            Button {
                interaction.duplicate(event)
            } label: {
                Label(CalendarResourcesStrings.buttonDuplicate, symbol: .squaresStackedPlus)
            }
        }

        Section {
            Button {
                EventPasteboard.copy(transferItem)
            } label: {
                Label(CalendarResourcesStrings.buttonCopy, symbol: .squaresStacked)
            }

            ShareLink(item: transferItem, preview: SharePreview(event.title)) {
                Label(CalendarResourcesStrings.shareLabel, symbol: .share)
            }
        }

        if event.myStatus != nil {
            Menu {
                ForEach([UIParticipationStatus.accepted, .tentative, .declined], id: \.self) { status in
                    Button {
                        interaction.reply(status, to: event)
                    } label: {
                        Label(status.buttonTitle, symbol: status.icon)
                    }
                    .disabled(event.myStatus == status)
                }
            } label: {
                Label(CalendarResourcesStrings.buttonRespond, symbol: .calendarCheck)
            }
        }

        if event.canEdit {
            Section {
                Button(role: .destructive) {
                    interaction.pendingDeletion = event
                } label: {
                    Label(CalendarResourcesStrings.buttonDeleteEvent, symbol: .trash)
                }
            }
        }
    }
}
