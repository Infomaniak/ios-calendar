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
import ESDSFoundation
import SwiftUI

struct DayView: View {
    enum Constants {
        static let verticalInset = DayTimelineView.Constants.labelFontSize / 2

        static let leadingInset: CGFloat = {
            let font = UIFont.systemFont(
                ofSize: DayTimelineView.Constants.labelFontSize,
                weight: .semibold
            )
            let largestLabelWidth = "00:00".size(withAttributes: [.font: font]).width

            return largestLabelWidth.rounded(.up) + DayTimelineView.Constants.labelSpacing
        }()

        enum PointsPerHour {
            static let minimum: CGFloat = 40
            static let `default`: CGFloat = 60
            static let maximum: CGFloat = 100
        }
    }

    @Environment(\.esdsTheme) private var theme

    @State private var scrollPosition = ScrollPosition()

    @State private var pointsPerHour = Constants.PointsPerHour.default
    @State private var currentMagnification: CGFloat = 1.0

    let date: Date
    let events: [CalendarCoreUI.UIEvent]

    private var hourMarks: [Date] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let startOfNextDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        var marks = [Date]()
        var currentMark = startOfDay
        while currentMark < startOfNextDay {
            marks.append(currentMark)
            guard let nextMark = Calendar.current.date(byAdding: .hour, value: 1, to: currentMark) else { break }
            currentMark = nextMark
        }

        marks.append(startOfNextDay)

        return marks
    }

    private var effectivePointsPerHour: CGFloat {
        return clampedPointsPerHour(pointsPerHour * currentMagnification)
    }

    private var viewHeight: CGFloat {
        return CGFloat(hourMarks.count - 1) * effectivePointsPerHour + Self.Constants.verticalInset * 2
    }

    var body: some View {
        TimelineView(.everyMinute) { _ in
            ScrollView {
                ZStack(alignment: .top) {
                    DayTimelineView(date: date, pointsPerHour: effectivePointsPerHour, leadingOffset: Self.Constants.leadingInset)

                    DayViewLayout(
                        verticalInset: Self.Constants.verticalInset,
                        leadingInset: Self.Constants.leadingInset,
                        pointsPerHour: effectivePointsPerHour
                    ) {
                        ForEach(events) { event in
                            DayEventView(event: event, pointsPerHour: effectivePointsPerHour)
                                .tag(event.startDate)
                        }
                    }
                }
                .frame(height: viewHeight)
            }
            .contentMargins(IKPadding.medium, for: .scrollContent)
            .scrollPosition($scrollPosition)
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        currentMagnification = value.magnification
                    }
                    .onEnded { value in
                        pointsPerHour = clampedPointsPerHour(pointsPerHour * value.magnification)
                        currentMagnification = 1.0
                    }
            )
        }
    }

    private func clampedPointsPerHour(_ value: CGFloat) -> CGFloat {
        return min(max(value, Constants.PointsPerHour.minimum), Constants.PointsPerHour.maximum)
    }
}

#Preview {
    DayView(date: .now, events: [.preview, .preview])
}
