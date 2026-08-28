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

private struct DayViewZoomFocus {
    let date: Date
    let verticalPosition: CGFloat
}

struct DayViewZoomModifier: ViewModifier {
    static let zoomSensitivity: CGFloat = 0.66

    @Environment(\.calendar) private var calendar

    @State private var zoomFocus: DayViewZoomFocus?

    @Binding var pointsPerHour: CGFloat
    @Binding var currentMagnification: CGFloat
    @Binding var scrollPosition: ScrollPosition

    let date: Date
    let scrollOffset: CGFloat
    let maximumElapsedHours: CGFloat

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        let focus = zoomFocus ?? zoomFocus(at: value.startLocation.y)
                        zoomFocus = focus

                        let magnification = adjustedMagnification(value.magnification)
                        let newPointsPerHour = DayContentView.Constants.PointsPerHour.clamped(pointsPerHour * magnification)
                        currentMagnification = magnification
                        scroll(to: focus, pointsPerHour: newPointsPerHour)
                    }
                    .onEnded { value in
                        let magnification = adjustedMagnification(value.magnification)
                        let newPointsPerHour = DayContentView.Constants.PointsPerHour.clamped(pointsPerHour * magnification)
                        if let zoomFocus {
                            scroll(to: zoomFocus, pointsPerHour: newPointsPerHour)
                        }

                        pointsPerHour = newPointsPerHour
                        currentMagnification = 1.0
                        zoomFocus = nil
                    }
            )
    }

    private func adjustedMagnification(_ magnification: CGFloat) -> CGFloat {
        return 1 + (magnification - 1) * Self.zoomSensitivity
    }

    private func zoomFocus(at verticalPosition: CGFloat) -> DayViewZoomFocus {
        let focusPosition = scrollOffset + verticalPosition - DayContentView.Constants.verticalInset
        let elapsedHours = focusPosition / pointsPerHour
        let clampedElapsedHours = min(max(elapsedHours, 0), maximumElapsedHours)
        let focusDate = calendar.startOfDay(for: date)
            .addingTimeInterval(TimeInterval(clampedElapsedHours) * 3600)

        return DayViewZoomFocus(date: focusDate, verticalPosition: verticalPosition)
    }

    private func scroll(to focus: DayViewZoomFocus, pointsPerHour: CGFloat) {
        let elapsedHours = focus.date.timeIntervalSince(calendar.startOfDay(for: date)) / 3600
        let focusPosition = elapsedHours * pointsPerHour + DayContentView.Constants.verticalInset
        scrollPosition.scrollTo(y: focusPosition - focus.verticalPosition)
    }
}

extension View {
    // swiftlint:disable:next function_parameter_count
    func dayViewZoom(
        pointsPerHour: Binding<CGFloat>,
        currentMagnification: Binding<CGFloat>,
        scrollPosition: Binding<ScrollPosition>,
        date: Date,
        scrollOffset: CGFloat,
        maximumElapsedHours: CGFloat
    ) -> some View {
        modifier(DayViewZoomModifier(
            pointsPerHour: pointsPerHour,
            currentMagnification: currentMagnification,
            scrollPosition: scrollPosition,
            date: date,
            scrollOffset: scrollOffset,
            maximumElapsedHours: maximumElapsedHours
        ))
    }
}
