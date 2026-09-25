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

import DesignSystem
import SwiftUI

enum TimelineViewConstants {
    enum PointsPerHour {
        static let minimum: CGFloat = 48
        static let `default`: CGFloat = 64
        static let maximum: CGFloat = 112

        static func clamped(_ value: CGFloat) -> CGFloat {
            return min(max(value, minimum), maximum)
        }
    }
}

struct TimelineContentView<EventContent: View, Overlay: View>: View {
    @Environment(\.calendar) private var calendar

    @State private var currentMagnification: CGFloat = 1.0
    @State private var pointsPerHour = TimelineViewConstants.PointsPerHour.default

    @Binding var scrollPosition: ScrollPosition
    @Binding var scrollOffset: CGFloat

    let date: Date
    @ViewBuilder let eventContent: (TimelineGeometry) -> EventContent
    @ViewBuilder let overlay: (TimelineGeometry) -> Overlay

    private var maximumElapsedHours: CGFloat {
        let startOfDay = calendar.startOfDay(for: date)
        guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }

        return startOfNextDay.timeIntervalSince(startOfDay) / 3600
    }

    private var effectivePointsPerHour: CGFloat {
        return TimelineViewConstants.PointsPerHour.clamped(pointsPerHour * currentMagnification)
    }

    private var contentHeight: CGFloat {
        return maximumElapsedHours * effectivePointsPerHour + TimelineBackgroundView.Constants.verticalInset * 2
    }

    var body: some View {
        ScrollView {
            GeometryReader { _ in
                let geometry = TimelineGeometry(
                    startOfDay: calendar.startOfDay(for: date),
                    pointsPerHour: effectivePointsPerHour
                )

                ZStack(alignment: .topLeading) {
                    TimelineBackgroundView(
                        date: date,
                        pointsPerHour: geometry.pointsPerHour,
                        leadingOffset: TimelineBackgroundView.Constants.leadingInset,
                        verticalOffset: TimelineBackgroundView.Constants.verticalInset
                    )
                    .padding(.horizontal, value: .medium)

                    eventContent(geometry)
                        .padding(geometry.eventLayoutPadding)
                }
                .overlay(alignment: .topLeading) {
                    overlay(geometry)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: contentHeight)
        }
        .contentMargins(.vertical, IKPadding.small, for: .scrollContent)
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: CGFloat.self) { scrollProxy in
            scrollProxy.contentOffset.y + scrollProxy.contentInsets.top
        } action: { _, newValue in
            scrollOffset = newValue
        }
        .timelineZoom(
            pointsPerHour: $pointsPerHour,
            currentMagnification: $currentMagnification,
            scrollPosition: $scrollPosition,
            date: date,
            scrollOffset: scrollOffset,
            maximumElapsedHours: maximumElapsedHours
        )
    }
}
