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
import DesignSystem
import SwiftUI

struct EventCellStyle: ViewModifier {
    enum Mode: Equatable {
        case `default`
        case maybe
        case declined
        case pending
    }

    let mode: Mode
    let colors: CalendarCoreUI.UIEvent.Colors
    let padding: CGFloat

    init(event: CalendarCoreUI.UIEvent, padding: CGFloat) {
        colors = event.colors
        self.padding = padding
        mode = Self.computeMode(for: event)
    }

    // periphery:ignore - Used for #Preview
    init(mode: Mode, colors: CalendarCoreUI.UIEvent.Colors = .preview) {
        self.mode = mode
        self.colors = colors
        padding = IKPadding.mini
    }

    private var foreground: Color {
        switch mode {
        case .default, .maybe, .declined:
            return colors.onContainerColor
        case .pending:
            return colors.onContainerVariantColor
        }
    }

    @ViewBuilder
    private var background: some View {
        switch mode {
        case .default, .declined:
            colors.containerColor
        case .maybe:
            DiagonalStripesView(color: colors.containerColor)
        case .pending:
            colors.containerVariantColor
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(mode == .declined ? 0.5 : 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .foregroundStyle(foreground)
            .background(background.opacity(0.75))
            .overlay(alignment: .leading) {
                colors.onContainerColor.frame(width: 4)
            }
            .strikethrough(mode == .declined)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(colors.onContainerColor)
                    .frame(width: 4)
            }
            .clipShape(.rect(cornerRadius: 8))
            .overlay {
                if mode == .pending {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(colors.onContainerColor, lineWidth: 1)
                }
            }
    }

    private static func computeMode(for event: CalendarCoreUI.UIEvent) -> Mode {
        if event.status == .cancelled {
            return .declined
        }

        guard let attendee = event.user else {
            return .default
        }

        switch attendee.status {
        case .accepted:
            return .default
        case .declined:
            return .declined
        case .tentative:
            return .maybe
        case .needsAction:
            return .pending
        }
    }
}

extension View {
    func eventCellStyle(event: CalendarCoreUI.UIEvent, padding: CGFloat = IKPadding.mini) -> some View {
        modifier(EventCellStyle(event: event, padding: padding))
    }

    // periphery:ignore - Used for #Preview
    func eventCellStyle(mode: EventCellStyle.Mode) -> some View {
        modifier(EventCellStyle(mode: mode))
    }
}

#Preview {
    VStack {
        Text("Default")
            .eventCellStyle(mode: .default)

        Text("Maybe")
            .eventCellStyle(mode: .maybe)

        Text("Declined")
            .eventCellStyle(mode: .declined)

        Text("Pending")
            .eventCellStyle(mode: .pending)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
