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
import InfomaniakCore
import SwiftUI

public extension View {
    func colorSchemeModifier() -> some View {
        modifier(ColorSchemeModifier())
    }
}

struct ColorSchemeModifier: ViewModifier {
    @AppStorage(UserDefaults.shared.key(.theme), store: .shared)
    private var theme = DefaultPreferences.theme

    func body(content: Content) -> some View {
        content
            .onChange(of: theme, initial: true) { _, newTheme in
                updateUI(theme: newTheme)
            }
            .preferredColorScheme(theme.colorScheme)
    }

    private func updateUI(theme: Theme) {
        #if canImport(UIKit)
        let allWindows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        for window in allWindows {
            window.updateUI(theme: theme)
        }
        #endif
    }
}
