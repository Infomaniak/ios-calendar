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

import CalendarResources
import ESDSFoundation
import CalendarCore
import SwiftUI

public struct GeneralSettingsView: View {
    @Environment(\.esdsTheme) private var theme

    @AppStorage(UserDefaults.standard.key(.isShowWeekends), store: .standard)
    private var isShowWeekends: Bool = DefaultPreferences.isShowWeekends

    public init() {}

    public var body: some View {
        List {
            Section {
                NavigationLink(destination: EmptyView()) {
                    Text("Calendrier par défaut")
                }
                .disabled(true)
            } header: {
                Text("Par défaut")
            }

            Section {
                NavigationLink(destination: ThemeSettingsView()) {
                    Text("Thème")
                }

                NavigationLink(destination: StartDaySettingsView()) {
                    Text("Début de la semaine")
                }

                Toggle("Afficher les week-ends", isOn: $isShowWeekends)
                    .toggleStyle(SwitchToggleStyle())
            } header: {
                Text("Par défaut")
            }
        }
    }
}

#Preview {
    GeneralSettingsView()
}
