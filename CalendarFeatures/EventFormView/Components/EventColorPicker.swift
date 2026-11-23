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
import CalendarResources
import ESDSFoundation
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

struct EventColorPicker: View {
    @Environment(\.esdsTheme) private var theme

    @State private var colors: [NamedColor]?

    @Binding var selectedColor: Int32?

    let calendarId: String?

    private var isCustomColor: Bool {
        guard let selectedColor else { return false }
        guard let colors else { return true }
        return !colors.contains { $0.sourceColor == selectedColor }
    }

    var body: some View {
        Menu {
            if let colors {
                ForEach(colors, id: \.sourceColor) { namedColor in
                    Button {
                        selectedColor = namedColor.sourceColor
                    } label: {
                        ColorDotLabel(name: namedColor.name, color: Color(argb: namedColor.sourceColor))
                    }
                }
            }
        } label: {
            HStack {
                if let selectedColor {
                    Image(systemName: "chevron.up.chevron.down")
                        .accessibilityHidden(true)
                        .foregroundStyle(theme.color.contentSecondary)
                    ColorDotLabel(color: Color(argb: selectedColor))
                }
            }
        }
        .buttonStyle(.plain)
        .task(id: calendarId) {
            await loadColors()
        }
    }

    private func loadColors() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        let previousDefaultColor = colors?.first?.sourceColor
        guard let calendarId,
              let colors = try? await calendarSDK.calendarManager.getColorChoices(calendarId: calendarId) else { return }
        self.colors = colors
        if selectedColor == nil || selectedColor == previousDefaultColor {
            selectedColor = colors.first?.sourceColor
        } else if let selectedColor, isCustomColor {
            self.colors?.append(NamedColor(sourceColor: selectedColor, name: CalendarResourcesStrings.customColorLabel))
        }
    }
}
