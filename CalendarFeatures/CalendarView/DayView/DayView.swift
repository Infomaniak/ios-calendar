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
import Eventually
import SwiftUI

struct DayView: View {
    @Environment(\.calendar) private var calendar
    @Environment(DaysViewModel.self) private var daysViewModel

    @Binding var selectedEvent: CalendarCoreUI.UIEvent?

    let date: Date

    var body: some View {
        DayContentView(selectedEvent: $selectedEvent, date: date, events: daysViewModel.events(for: date, calendar: calendar))
    }
}

struct DayContentView: View {
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
            static let `default`: CGFloat = 64
            static let maximum: CGFloat = 100
        }
    }

    @Environment(\.calendar) private var calendar
    @Environment(MainViewState.self) private var mainViewState

    @SceneStorage("DayViewScrollPosition") private var storedScrollPosition = 0.0
    @State private var scrollPosition = ScrollPosition()

    @State private var pointsPerHour = Constants.PointsPerHour.default
    @State private var effectivePointsPerHour = Constants.PointsPerHour.default

    @State private var coveredTextHeights: [Int: CGFloat] = [:]

    @Binding var selectedEvent: CalendarCoreUI.UIEvent?
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

    private var viewHeight: CGFloat {
        return CGFloat(hourMarks.count - 1) * effectivePointsPerHour + Self.Constants.verticalInset * 2
    }

    var body: some View {
        GeometryReader { proxy in
        TimelineView(.everyMinute) { timeline in
            let allDayEvents = events.filter(\.isAllDay)
            Group {
                if #available(iOS 26.0, *) {
                    timelineContent(currentDate: timeline.date)
                        .safeAreaBar(edge: .top) {
                            FullDayEventView(events: allDayEvents, date: date)
                                .glassEffect(.identity, in: Rectangle())
                        }
                } else {
                    timelineContent(currentDate: timeline.date)
                        .safeAreaInset(edge: .top) {
                            FullDayEventView(events: allDayEvents, date: date)
                                .background(Material.bar)
                        }
                        .padding(.leading, Self.Constants.leadingInset)
                        .padding(.vertical, Self.Constants.verticalInset)

                    if calendar.isDate(date, inSameDayAs: timeline.date) {
                        TimelineIndicatorView(date: timeline.date)
                            .padding(.leading, value: .medium)
                            .visualEffect { content, proxy in
                                content
                                    .offset(y: -proxy.size.height / 2 + timeIndicatorPosition(at: timeline.date))
                            }
                    }
                }
                .scrollPosition($scrollPosition)
                .onScrollGeometryChange(for: CGFloat.self) { scrollProxy in
                    scrollProxy.contentOffset.y
                } action: { _, newValue in
                    guard mainViewState.selectedDate == date else { return }
                    storedScrollPosition = Double(newValue)
                }
                .onAppear {
                    scrollToCorrectPosition(proxy)
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
    }

    private func timelineContent(currentDate: Date) -> some View {
        ScrollView {
            ZStack(alignment: .top) {
                DayTimelineView(date: date, pointsPerHour: effectivePointsPerHour, leadingOffset: Self.Constants.leadingInset)

                EventuallyLayout(
                    startOfDay: calendar.startOfDay(for: date),
                    hourSlotHeight: effectivePointsPerHour
                ) { textHeights in
                    guard coveredTextHeights != textHeights else { return }
                    coveredTextHeights = textHeights
                } {
                    ForEach(Array(events.filter { !$0.isAllDay }.enumerated()), id: \.element.id) { index, event in
                        DayEventView(
                            event: event,
                            pointsPerHour: effectivePointsPerHour,
                            maxTextHeight: coveredTextHeights[index]
                        )
                        .eventuallyDateIntervalLayout(
                            DateInterval(
                                start: event.startDate,
                                end: event.endDate
                            )
                        )
                    }
                }
                .padding(.leading, Self.Constants.leadingInset)
                .padding(.vertical, Self.Constants.verticalInset)

                TimelineIndicatorView(date: currentDate, pointsPerHour: effectivePointsPerHour)
            }
            .frame(height: viewHeight)
            .id(timelineId)
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        unitAnchorState = value.startAnchor
                        let newPointsPerHour = pointsPerHour * value.magnification
                        effectivePointsPerHour = clampedPointsPerHour(newPointsPerHour)
                        positionId = timelineId
                    }
                    .onEnded { _ in
                        pointsPerHour = effectivePointsPerHour
                    }
            )
        }
        .scrollPosition(id: $positionId, anchor: unitAnchorState)
    }

    private func clampedPointsPerHour(_ value: CGFloat) -> CGFloat {
        return min(max(value, Constants.PointsPerHour.minimum), Constants.PointsPerHour.maximum)
    }

    private func timeIndicatorPosition(at date: Date) -> CGFloat {
        let elapsedTime = date.timeIntervalSince(calendar.startOfDay(for: date)) / 3600
        return elapsedTime * effectivePointsPerHour + Self.Constants.verticalInset
    }

    private func scrollToCorrectPosition(_ proxy: GeometryProxy) {
        if calendar.isDate(date, inSameDayAs: .now) {
            let currentTimePosition = timeIndicatorPosition(at: .now)
            scrollPosition.scrollTo(y: currentTimePosition - proxy.size.height / 2)
        } else {
            scrollPosition.scrollTo(y: storedScrollPosition)
        }
    }
}

#Preview {
    DayContentView(selectedEvent: .constant(nil), date: .now, events: [.preview, .preview])
}
