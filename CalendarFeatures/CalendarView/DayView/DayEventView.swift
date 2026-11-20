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

struct DayEventView: View {
    let event: UIEventSummary
    let pointsPerHour: CGFloat
    let maxVisibleHeight: CGFloat?

    init(event: UIEventSummary, pointsPerHour: CGFloat, maxVisibleHeight: CGFloat? = nil) {
        self.event = event
        self.pointsPerHour = pointsPerHour
        self.maxVisibleHeight = maxVisibleHeight
    }

    private var visibleContentHeight: CGFloat {
        return maxVisibleHeight ?? cellFullHeight
    }

    private var cellFullHeight: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600

        let cappedHours = min(max(hours, 0.25), 24)

        let eventHeight = CGFloat(cappedHours) * pointsPerHour
        return max(eventHeight - 2 * DayContentView.Constants.layoutVerticalSpacing, 16)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            largeCell
            mediumCell
            smallCell
            compactCell
            ultraCompactCell
        }
        .frame(maxHeight: visibleContentHeight, alignment: .top)
        .frame(height: cellFullHeight, alignment: .top)
        .eventCellStyle(event: event)
    }

    private var largeCell: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                Text(event.displayTitle)
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                EventIconsView(event: event, shouldShowLocationIcon: false)
            }

            if let location = event.location {
                Text(location)
                    .font(.caption2)
                    .lineLimit(1)
            }

            Text(event.startDate ..< event.endDate, format: .eventTimeBounds)
                .font(.caption2)
        }
        .padding(.vertical, 4)
        .padding(.trailing, 8)
    }

    private var mediumCell: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                Text(event.displayTitle)
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                EventIconsView(event: event, shouldShowLocationIcon: false)
            }

            if let location = event.location {
                Text(location)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .padding(.trailing, 8)
    }

    private var smallCell: some View {
        HStack(alignment: .top) {
            Text(event.displayTitle)
                .font(.caption.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            EventIconsView(event: event)
        }
        .padding(.vertical, 4)
        .padding(.trailing, 8)
    }

    private var compactCell: some View {
        Text(event.displayTitle)
            .font(.caption.bold())
            .padding(.vertical, 4)
            .padding(.trailing, 2)
    }

    private var ultraCompactCell: some View {
        Text(event.displayTitle)
            .font(.caption.bold())
            .minimumScaleFactor(0.9)
            .padding(.vertical, 1)
            .padding(.trailing, 2)
    }
}

#Preview {
    VStack {
        DayEventView(event: .mediumPreview, pointsPerHour: TimelineViewConstants.PointsPerHour.default)
        DayEventView(event: .preview, pointsPerHour: TimelineViewConstants.PointsPerHour.default)
        DayEventView(event: .shortPreview, pointsPerHour: TimelineViewConstants.PointsPerHour.default)
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(.gray.opacity(0.2))
}
