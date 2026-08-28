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
import CalendarResources
import ESDSFoundation
import SwiftUI

public struct GeneralSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.esdsTheme) private var theme

    @State private var defaultEventDuration: DefaultEventDuration = UserDefaults.standard.defaultEventDuration

    public init() {}

    public var body: some View {
        @Bindable var settings = settings

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
                NavigationLink {
                    SettingsOptionsListView(
                        navigationTitle: "Thème",
                        header: "Choix du thème",
                        selection: $settings.theme
                    )
                } label: {
                    Text("Thème")
                }

                NavigationLink {
                    SettingsOptionsListView(
                        navigationTitle: "Début de la semaine",
                        header: "La semaine commence le",
                        selection: $settings.startDay
                    )
                } label: {
                    Text("Début de la semaine")
                }

                Toggle("Afficher les week-ends", isOn: $settings.isShowWeekends)
                    .toggleStyle(SwitchToggleStyle())
            } header: {
                Text("Par défaut")
            }

            Section {
                NavigationLink {
                    SettingsOptionsListView(
                        navigationTitle: "Durée d'un évènement par défaut",
                        header: "Durée d'un évènement",
                        selection: $settings.defaultEventDuration
                    )
                } label: {
                    VStack(alignment: .leading) {
                        Text("Durée d'un évènement par défaut")
                        Text(settings.defaultEventDuration.title)
                            .foregroundStyle(theme.color.contentSecondary)
                    }
                }
            } header: {
                Text("Évènement")
            }
        }
    }
}

#Preview {
    GeneralSettingsView()
}
