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

            let fakeDate = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? .now
            let labelWidth = fakeDate.formatted(DayTimelineView.Constants.dateFormater)
                .size(withAttributes: [.font: font]).width + 2 * IKPadding.mini

            return labelWidth.rounded(.up) + DayTimelineView.Constants.labelSpacing
        }()

        // swiftlint:disable:next nesting
        enum PointsPerHour {
            static let minimum: CGFloat = 40
            static let `default`: CGFloat = 60
            static let maximum: CGFloat = 100
        }
    }

    @Environment(\.calendar) private var calendar

    @State private var scrollPosition = ScrollPosition()

    @State private var pointsPerHour = Constants.PointsPerHour.default
    @State private var currentMagnification: CGFloat = 1.0

    let onSelectEvent: (CalendarCoreUI.UIEvent) -> Void
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
        TimelineView(.everyMinute) { timeline in
            ScrollView {
                ZStack(alignment: .top) {
                    DayTimelineView(date: date, pointsPerHour: effectivePointsPerHour, leadingOffset: Self.Constants.leadingInset)
                        .padding(.horizontal, value: .medium)

                    DayViewLayout(
                        calendar: calendar,
                        verticalInset: Self.Constants.verticalInset,
                        leadingInset: Self.Constants.leadingInset + IKPadding.medium,
                        trailingInset: IKPadding.medium,
                        pointsPerHour: effectivePointsPerHour
                    ) {
                        ForEach(events) { event in
                            Button {
                                onSelectEvent(event)
                            } label: {
                                DayEventView(event: event, pointsPerHour: effectivePointsPerHour)
                            }
                            .buttonStyle(.plain)
                            .tag(event.startDate)
                        }
                    }

                    if calendar.isDate(date, inSameDayAs: timeline.date) {
                        TimelineIndicatorView(date: timeline.date)
                            .padding(.leading, value: .medium)
                            .visualEffect { content, proxy in
                                content
                                    .offset(y: -proxy.size.height / 2 + timeIndicatorPosition(at: timeline.date))
                            }
                    }
                }
                .frame(height: viewHeight)
            }
            .scrollPosition($scrollPosition)
            .onAppear {
                let currentTimePosition = timeIndicatorPosition(at: .now)
                scrollPosition.scrollTo(y: currentTimePosition - IKPadding.huge)
            }
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

    private func timeIndicatorPosition(at date: Date) -> CGFloat {
        let elapsedTime = date.timeIntervalSince(calendar.startOfDay(for: date)) / 3600
        return elapsedTime * effectivePointsPerHour + Self.Constants.verticalInset
    }
}

#Preview {
    DayView(onSelectEvent: { _ in }, date: .now, events: [.preview, .preview])
}
