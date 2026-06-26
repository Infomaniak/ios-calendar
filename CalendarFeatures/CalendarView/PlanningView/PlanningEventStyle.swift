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

struct PlanningEventStyle: ViewModifier {
    enum Mode: Equatable {
        case `default`
        case maybe
        case declined
        case pending
    }

    let mode: Mode
    let colors: CalendarCoreUI.UIEvent.Colors

    init(event: CalendarCoreUI.UIEvent) {
        colors = event.colors
        mode = Self.computeMode(for: event)
    }

    // periphery:ignore - Used for #Preview
    init(mode: Mode, colors: CalendarCoreUI.UIEvent.Colors = .preview) {
        self.mode = mode
        self.colors = colors
    }

    private var foreground: Color {
        switch mode {
        case .default, .maybe, .declined:
            return colors.onDatavizContainerVariant
        case .pending:
            return colors.onDatavizContainer
        }
    }

    @ViewBuilder
    private var background: some View {
        switch mode {
        case .default, .declined:
            colors.datavizContainerVariant
        case .maybe:
            DiagonalStripesView(color: colors.datavizContainerVariant)
        case .pending:
            colors.datavizContainer
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(mode == .declined ? 0.5 : 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .foregroundStyle(foreground)
            .background(background)
            .strikethrough(mode == .declined)
            .clipShape(.rect(cornerRadius: 8))
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
    func planningEventStyle(event: CalendarCoreUI.UIEvent) -> some View {
        modifier(PlanningEventStyle(event: event))
    }

    // periphery:ignore - Used for #Preview
    func planningEventStyle(mode: PlanningEventStyle.Mode) -> some View {
        modifier(PlanningEventStyle(mode: mode))
    }
}

#Preview {
    VStack {
        Text("Default")
            .planningEventStyle(mode: .default)

        Text("Maybe")
            .planningEventStyle(mode: .maybe)

        Text("Declined")
            .planningEventStyle(mode: .declined)

        Text("Pending")
            .planningEventStyle(mode: .pending)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
