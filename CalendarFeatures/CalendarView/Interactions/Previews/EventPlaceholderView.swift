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

struct EventPlaceholderView: View {
    enum Style {
        case timeline
        case compact
    }

    let placeholder: EventPlaceholder
    var style = Style.timeline

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(placeholder.title)
                .font(.caption.bold())
                .lineLimit(style == .compact ? 1 : 2)

            if style == .timeline && !placeholder.isAllDay {
                Text(placeholder.start ..< placeholder.end, format: .eventTimeBounds)
                    .font(.caption2)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, style == .timeline ? IKPadding.mini : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: style == .timeline ? .topLeading : .leading)
        .eventCellStyle(event: placeholder, cornerRadius: style == .compact ? 4 : 8)
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

#Preview {
    VStack {
        EventPlaceholderView(placeholder: EventPlaceholder(moving: .preview, to: .now))
            .frame(height: 80)

        EventPlaceholderView(
            placeholder: EventPlaceholder(
                creationWithColors: .preview,
                isAllDay: false,
                start: .now,
                end: .now.addingTimeInterval(3600)
            )
        )
        .frame(height: 80)

        EventPlaceholderView(placeholder: EventPlaceholder(moving: .preview, to: .now), style: .compact)
            .frame(height: 20)
    }
    .frame(maxWidth: 200)
    .padding()
}
