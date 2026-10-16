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

struct TimelineGeometry {
    let startOfDay: Date
    let pointsPerHour: CGFloat
    let contentHeight: CGFloat
    let visibleHeight: CGFloat

    var eventLayoutPadding: EdgeInsets {
        let verticalInset = TimelineBackgroundView.Constants.verticalInset - TimelineBackgroundView.Constants.indexHeight / 2

        return EdgeInsets(
            top: verticalInset,
            leading: TimelineBackgroundView.Constants.leadingInset,
            bottom: verticalInset,
            trailing: 0
        )
    }

    var horizontalLayoutPointsPerHour: CGFloat {
        let step = TimelineViewConstants.PointsPerHour.horizontalRelayoutStep
        let minimum = TimelineViewConstants.PointsPerHour.minimum
        guard step > 0 else { return pointsPerHour }

        let stepIndex = ((pointsPerHour - minimum) / step).rounded(.toNearestOrAwayFromZero)
        return TimelineViewConstants.PointsPerHour.clamped(minimum + stepIndex * step)
    }

    func yPosition(for date: Date, calendar: Calendar) -> CGFloat {
        let elapsedHours = date.timeIntervalSince(calendar.startOfDay(for: date)) / 3600
        return elapsedHours * pointsPerHour + TimelineBackgroundView.Constants.verticalInset
    }

    func centeredScrollOffset(for date: Date, calendar: Calendar) -> CGFloat {
        let centeredOffset = yPosition(for: date, calendar: calendar) - visibleHeight / 2
        let maximumOffset = max(contentHeight - visibleHeight, 0)
        return min(max(centeredOffset, 0), maximumOffset)
    }
}
