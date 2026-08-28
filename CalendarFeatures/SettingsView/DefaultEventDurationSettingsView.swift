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

public struct DefaultEventDurationSettingsView: View {
    @Environment(\.esdsTheme) private var theme

    @State private var defaultEventDuration: DefaultEventDuration = UserDefaults.standard.defaultEventDuration

    public init() {}

    public var body: some View {
        List {
            Section(header: Text("Durée d'un évènement")) {
                ForEach(DefaultEventDuration.allCases, id: \.self) { duration in
                    Button {
                        defaultEventDuration = duration
                        UserDefaults.standard.defaultEventDuration = duration
                    } label: {
                        HStack {
                            Text(duration.title)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if duration == defaultEventDuration {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.color.contentPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Durée d'un évènement par défaut")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DefaultEventDurationSettingsView()
}
