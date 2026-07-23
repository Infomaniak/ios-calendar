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

struct DayEventView: View {
    let event: CalendarCoreUI.UIEvent
    let pointsPerHour: CGFloat

    private var height: CGFloat {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = duration / 3600

        let cappedHours = min(max(hours, 0.25), 24)
        return CGFloat(cappedHours) * pointsPerHour
    }

    var body: some View {
        HStack {
            ViewThatFits(in: .vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(event.startDate ..< event.endDate, format: .eventTimeBounds)
                        .font(.caption2)

                    Text(event.title)
                        .lineLimit(1)
                        .font(.caption.bold())
                }

                Text(event.title)
                    .lineLimit(1)
                    .font(.caption.bold())
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            EventIconsView(event: event)
        }
        .frame(height: height, alignment: .top)
        .eventCellStyle(event: event)
    }
}

#Preview {
    VStack {
        DayEventView(event: .mediumPreview, pointsPerHour: DayView.Constants.PointsPerHour.default)
        DayEventView(event: .preview, pointsPerHour: DayView.Constants.PointsPerHour.default)
        DayEventView(event: .shortPreview, pointsPerHour: DayView.Constants.PointsPerHour.default)
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(.gray.opacity(0.2))
}
