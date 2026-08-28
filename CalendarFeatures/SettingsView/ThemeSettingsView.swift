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

public struct ThemeSettingsView: View {
    @Environment(\.esdsTheme) private var theme

    @AppStorage(UserDefaults.standard.key(.theme), store: UserDefaults.standard)
    private var appTheme: Theme = DefaultPreferences.theme

    public init() {}

    public var body: some View {
        List {
            Section(header: Text("Choix du thème")) {
                ForEach(Theme.allCases, id: \.self) { themeCase in
                    Button {
                        appTheme = themeCase
                    } label: {
                        HStack {
                            if let image = themeCase.image {
                                image
                            }
                            Text(themeCase.title)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if themeCase == appTheme {
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
        .navigationTitle("Thème")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ThemeSettingsView()
}
