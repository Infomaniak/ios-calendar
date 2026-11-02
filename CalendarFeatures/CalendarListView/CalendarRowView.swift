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

import SwiftUI
import CalendarCoreUI
import ESDSFoundation

struct CalendarRowView: View {
    @Environment(\.esdsTheme) private var theme

    let calendar: UICalendar
    let isVisible: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .strokeBorder(calendar.color, lineWidth: 2)
                    .background(Circle().fill(isVisible ? calendar.color : .clear))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isVisible {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white) // TODO: Use a color that contrasts well with the calendar color
                                .checkmarkTransition()
                                .animation(.spring(duration: 0.25), value: isVisible)
                        }
                    }
                    .accessibilityHidden(true)

                Text(calendar.displayName)
                    .lineLimit(1)
                    .foregroundStyle(theme.color.contentPrimary)

            }
        }
    }
}

private extension View {
    func checkmarkTransition() -> some View {
        if #available(iOS 26.0, *) {
            return transition(.symbolEffect(.drawOn))
        } else {
            return transition(.opacity)
        }
    }
}
