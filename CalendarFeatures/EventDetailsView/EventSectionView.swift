//
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
import SwiftUI

struct EventSectionView: View {
    let event: CalendarCoreUI.UIEvent

    var body: some View {
        Section {
            LabeledContent("Titre", value: event.title)
            LabeledContent("Lieu ou salle", value: event.location ?? "...")
            Toggle("Toute la journée", isOn: .constant(event.isAllDay))
                .disabled(true)
            LabeledContent("Début", value: event.startDate, format: .dateTime)
            LabeledContent("Fin", value: event.endDate, format: .dateTime)
        } header: {
            Text("Évènement")
        }
    }
}
