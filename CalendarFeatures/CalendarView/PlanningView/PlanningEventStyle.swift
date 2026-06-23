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

struct PlanningEventStyle: ViewModifier {
    let event: CalendarCoreUI.UIEvent

    private var primaryColor: Color {
        return Color.purple
    }

    private var secondaryColor: Color {
        return Color.purple.opacity(0.5)
    }

    @ContentBuilder
    private var background: some View {
        switch event.status {
        case .tentative:
            EmptyView()
        case .cancelled:
            DiagonalStripesView(color: secondaryColor)
        default:
            secondaryColor
        }
    }

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(background)
            .clipShape(.rect(cornerRadius: 8))
    }
}

extension View {
    func planningEventStyle(event: CalendarCoreUI.UIEvent) -> some View {
        modifier(PlanningEventStyle(event: event))
    }
}

#Preview {
    Text("Hello")
        .planningEventStyle(event: .preview)
}
