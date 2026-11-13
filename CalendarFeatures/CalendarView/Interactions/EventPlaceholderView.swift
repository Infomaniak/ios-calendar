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

/// The event being created or moved, lifted above the calendar.
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
        .padding(.leading, value: .micro)
        .padding(.vertical, style == .timeline ? IKPadding.mini : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: style == .timeline ? .topLeading : .leading)
        .eventCellStyle(colors: placeholder.colors, padding: 0)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

/// Card standing for an event outside of the calendar grid: drag preview (also shown over other apps) and context menu preview.
struct EventPreviewCard: View {
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
        .padding(.vertical, style == .contextMenu ? IKPadding.micro : 0)
        .eventCellStyle(event: event)
        .frame(width: style.width)
    }
}

/// Draws the placeholder of the day column `date` of a timeline.
struct TimelinePlaceholderLayer: View {
    @Environment(\.calendar) private var calendar
    @Environment(EventInteractionModel.self) private var interaction

    let date: Date
    let pointsPerHour: CGFloat

    private var placeholder: EventPlaceholder? {
        guard let placeholder = interaction.placeholder,
              !placeholder.isAllDay,
              calendar.isDate(placeholder.start, inSameDayAs: date) else { return nil }
        return placeholder
    }

    var body: some View {
        ZStack(alignment: .top) {
            if let placeholder {
                let startOfDay = calendar.startOfDay(for: date)
                let height = CGFloat(placeholder.duration / 3600) * pointsPerHour
                let minimumHeight = CGFloat(EventInteractionModel.snapInterval / 3600) * pointsPerHour

                EventPlaceholderView(placeholder: placeholder)
                    .frame(height: max(height, minimumHeight) - 2 * DayContentView.Constants.layoutVerticalSpacing)
                    .offset(
                        y: CGFloat(placeholder.start.timeIntervalSince(startOfDay) / 3600) * pointsPerHour
                            + DayContentView.Constants.layoutVerticalSpacing
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.snappy(duration: 0.2), value: placeholder)
    }
}
