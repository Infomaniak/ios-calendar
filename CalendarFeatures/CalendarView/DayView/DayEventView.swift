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
    let event: CalendarCoreUI.UIEvent
    let pointsPerHour: CGFloat
    let maxTextHeight: CGFloat?

    init(event: CalendarCoreUI.UIEvent, pointsPerHour: CGFloat, maxTextHeight: CGFloat? = nil) {
        self.event = event
        self.pointsPerHour = pointsPerHour
        self.maxTextHeight = maxTextHeight
    }

    private var height: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600

        let cappedHours = min(max(hours, 0.25), 24)
        return CGFloat(cappedHours) * pointsPerHour
    }

    private var effectiveHeight: CGFloat {
        maxTextHeight ?? height
    }

    private var contentPadding: EdgeInsets {
        let padding: CGFloat = effectiveHeight > 15 ? IKPadding.mini : 0
        return EdgeInsets(top: padding, leading: IKPadding.mini,
                          bottom: 0, trailing: IKPadding.mini)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(event.title)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    EventIconsView(event: event, shouldShowLocationIcon: false)
                }

                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .lineLimit(1)
                }

                Text(event.startDate ..< event.endDate, format: .eventTimeBounds)
                    .font(.caption2)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(event.title)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    EventIconsView(event: event, shouldShowLocationIcon: false)
                }

                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }

            HStack {
                Text(event.title)
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                EventIconsView(event: event)
            }

            Text(event.title)
                .font(.caption.bold())
        }
        .padding(contentPadding)
        .frame(maxHeight: effectiveHeight, alignment: .top)
        .frame(height: height, alignment: .top)
        .eventCellStyle(event: event, padding: 0)
        .opacity(0.75)
    }
}

#Preview {
    VStack {
        DayEventView(event: .mediumPreview, pointsPerHour: DayContentView.Constants.PointsPerHour.default)
        DayEventView(event: .preview, pointsPerHour: DayContentView.Constants.PointsPerHour.default)
        DayEventView(event: .shortPreview, pointsPerHour: DayContentView.Constants.PointsPerHour.default)
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(.gray.opacity(0.2))
}
