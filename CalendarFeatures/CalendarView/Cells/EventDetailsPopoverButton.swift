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
import CalendarEventDetailsView
import SwiftUI

struct EventDetailsPopoverButton<Label: View>: View {
    @Environment(MainViewState.self) private var mainViewState

    let event: CalendarCoreUI.UIEvent
    @ViewBuilder let label: Label

    private var presentedEvent: Binding<CalendarCoreUI.UIEvent?> {
        return Binding(
            get: {
                mainViewState.presentedEvent?.id == event.id ? event : nil
            },
            set: { newValue in
                if newValue == nil {
                    mainViewState.presentedEvent = nil
                }
            }
        )
    }

    var body: some View {
        Button { mainViewState.presentedEvent = event } label: { label }
            .buttonStyle(.plain)
            .popover(item: presentedEvent) { event in
                EventDetailsView(event: event)
                    .selfSizingPopover(idealWidth: 400)
            }
    }
}
