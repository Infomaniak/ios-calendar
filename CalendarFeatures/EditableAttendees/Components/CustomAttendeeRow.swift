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

import CalendarResources
import ESDSFoundation
import ESDSSymbols
import SwiftUI

struct CustomAttendeeRow: View {
    @Environment(\.esdsTheme) private var theme

    let text: String
    let isValid: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(theme.color.backgroundElevationSunken)
                    .overlay {
                        ESDSSymbols.envelope.image
                            .font(.system(size: 24))
                            .foregroundStyle(theme.color.contentBrand)
                    }
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)

                VStack(alignment: .leading) {
                    Text(verbatim: text)
                        .font(.body)
                    if !isValid {
                        Text(CalendarResourcesStrings.attendeeIncompleteEmailMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .foregroundStyle(.primary)
        .allowsHitTesting(isValid)
    }
}

#Preview {
    VStack {
        CustomAttendeeRow(text: "Hello, World!", isValid: true) {}
        CustomAttendeeRow(text: "Hello, World!", isValid: false) {}
    }
}
