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

    private var defaultColor: NamedColor? {
        colors?.first
    }

    private var explicitChoices: [NamedColor] {
        Array(colors?.dropFirst() ?? [])
    }

    private var displayedColor: Int32? {
        selectedColor ?? defaultColor?.sourceColor
    }

    private var selectedColorName: String? {
        guard let selectedColor else { return defaultColor?.name }
        return colors?.first { $0.sourceColor == selectedColor }?.name ?? CalendarResourcesStrings.customColorLabel
    }

    var body: some View {
        Menu {
            if let defaultColor {
                Button {
                    selectedColor = nil
                } label: {
                    ColorDotLabel(name: defaultColor.name, color: Color(argb: defaultColor.sourceColor))
                }
            }

            ForEach(explicitChoices, id: \.sourceColor) { namedColor in
                Button {
                    guard selectedColor != namedColor.sourceColor else { return }
                    selectedColor = namedColor.sourceColor
                } label: {
                    ColorDotLabel(name: namedColor.name, color: Color(argb: namedColor.sourceColor))
                }
            }
        } label: {
            HStack {
                if let displayedColor {
                    Image(systemName: "chevron.up.chevron.down")
                        .accessibilityHidden(true)
                        .foregroundStyle(theme.color.contentSecondary)
                    ColorDotLabel(color: Color(argb: displayedColor))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(CalendarResourcesStrings.eventColorLabel))
        .accessibilityValue(Text(selectedColorName ?? ""))
        .task(id: calendarId) {
            await loadColors()
        }
    }

    private func loadColors() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        guard let calendarId,
              let colors = try? await calendarSDK.calendarManager.getColorChoices(calendarId: calendarId) else {
            colors = nil
            return
        }

        self.colors = colors
        if let selectedColor, !colors.contains(where: { $0.sourceColor == selectedColor }) {
            self.colors?.append(NamedColor(sourceColor: selectedColor, name: CalendarResourcesStrings.customColorLabel))
        }
    }
}
