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
import ESDSSymbols
import SwiftUI

struct EventRecurrenceRowView: View {
    @Environment(\.esdsTheme) private var theme

    @Binding var recurrence: EventRecurrence

    private var selectionBinding: Binding<EventRecurrence> {
        Binding(
            get: { recurrence },
            set: { newRecurrence in
                // TODO: The custom recurrence editor is not available yet.
                guard newRecurrence != .custom else { return }
                recurrence = newRecurrence
            }
        )
    }

    var body: some View {
        Picker(selection: selectionBinding) {
            Section {
                Text(EventRecurrence.none.label)
                    .tag(EventRecurrence.none)
                ForEach(EventRecurrence.presets, id: \.self) { preset in
                    Text(preset.label)
                        .tag(preset)
                }
            }

            Text(EventRecurrence.custom.label)
                .tag(EventRecurrence.custom)
        } label: {
            Label(CalendarResourcesStrings.recurrenceLabel, symbol: .circularArrowsClockwise)
                .labelStyle(.formLabel)
        }
        .tint(theme.color.contentTertiary)
        .pickerStyle(.menu)
    }
}

#Preview {
    @Previewable @State var recurrence = EventRecurrence.none

    Form {
        Section {
            EventRecurrenceRowView(recurrence: $recurrence)
        }
    }
}
