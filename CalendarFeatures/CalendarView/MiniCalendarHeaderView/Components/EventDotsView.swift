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

import ESDSFoundation
import SwiftUI

struct EventDotsView: View {
    @Environment(\.esdsTheme) private var theme

    let maxEventCount = 4
    let eventDots: [Color]

    var body: some View {
        HStack(spacing: 1) {
            if eventDots.isEmpty {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            } else if eventDots.count > maxEventCount - 1 {
                ForEach(eventDots.prefix(maxEventCount - 1), id: \.hashValue) { dot in
                    Circle()
                        .fill(dot)
                        .frame(width: 6, height: 6)
                }

                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(theme.color.iconSecondary)
            } else {
                ForEach(eventDots.prefix(maxEventCount), id: \.hashValue) { dot in
                    Circle()
                        .fill(dot)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

#Preview {
    EventDotsView(eventDots: [.red, .blue, .green])
}
