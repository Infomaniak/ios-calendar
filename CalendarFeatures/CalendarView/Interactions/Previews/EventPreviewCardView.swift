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

struct EventPreviewCardView: View {
    enum Style {
        case drag
        case contextMenu

        var width: CGFloat {
            switch self {
            case .drag:
                return 200
            case .contextMenu:
                return 280
            }
        }
    }

    let event: UIEventSummary
    let style: Style

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.displayTitle)
                .font(style == .drag ? .caption.bold() : .subheadline.bold())
                .lineLimit(2)

            if !event.isAllDay {
                Text(event.startDate ..< event.endDate, format: .eventTimeBounds)
                    .font(style == .drag ? .caption2 : .caption)
            }

            if style == .contextMenu, let location = event.location {
                Text(location)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .padding(.leading, value: .micro)
        .padding(.vertical, value: .micro)
        .eventCellStyle(event: event)
        .frame(width: style.width)
    }
}

#Preview {
    VStack {
        EventPreviewCardView(event: .preview, style: .drag)
        EventPreviewCardView(event: .preview, style: .contextMenu)
    }
    .padding()
}
