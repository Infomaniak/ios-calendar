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

    @Binding var miniCalendarHeight: CGFloat

    let date: Date

    var body: some View {
        DayContentView(
            date: date,
            events: daysViewModel.events(for: date, calendar: calendar),
            miniCalendarHeight: miniCalendarHeight
        )
    }
}

struct DayContentView: View {
    enum Constants {
        static let layoutHorizontalSpacing = IKPadding.micro
        static let layoutVerticalSpacing: CGFloat = 1.5

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
            static let minimum: CGFloat = 48
            static let `default`: CGFloat = 64
            static let maximum: CGFloat = 112

            static let horizontalRelayoutStep: CGFloat = 8

            static func clamped(_ value: CGFloat) -> CGFloat {
                return min(max(value, PointsPerHour.minimum), PointsPerHour.maximum)
            }
        }
    }

    @Environment(\.calendar) private var calendar
    @Environment(MainViewState.self) private var mainViewState

    @SceneStorage("DayViewScrollPosition") private var storedScrollPosition = 0.0
    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset: CGFloat = 0

    @State private var pointsPerHour = Constants.PointsPerHour.default
    @State private var currentMagnification: CGFloat = 1.0
    @State private var coveredTextHeights: [Int: CGFloat] = [:]

    let date: Date
    let events: [CalendarCoreUI.UIEvent]
    let miniCalendarHeight: CGFloat

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
        return Constants.PointsPerHour.clamped(pointsPerHour * currentMagnification)
    }

    private var viewHeight: CGFloat {
        return CGFloat(hourMarks.count - 1) * effectivePointsPerHour + Self.Constants.verticalInset * 2
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.everyMinute) { timeline in
                let horizontalPointsPerHour = horizontalLayoutPointsPerHour(
                    for: effectivePointsPerHour
                )

                ScrollView {
                    ZStack(alignment: .top) {
                        DayTimelineView(
                            date: date,
                            pointsPerHour: effectivePointsPerHour,
                            leadingOffset: Self.Constants.leadingInset
                        )
                        .padding(.horizontal, value: .medium)

                        EventuallyLayout(
                            startOfDay: calendar.startOfDay(for: date),
                            hourSlotHeight: effectivePointsPerHour,
                            horizontalHourSlotHeight: horizontalPointsPerHour,
                            config: .init(hSpacing: Constants.layoutHorizontalSpacing, vSpacing: Constants.layoutVerticalSpacing)
                        ) { textHeights in
                            guard coveredTextHeights != textHeights else { return }
                            coveredTextHeights = textHeights
                        } {
                            ForEach(Array(events.filter { !$0.isAllDay }.enumerated()), id: \.element.id) { index, event in
                                EventDetailsPopoverButton(event: event) {
                                    DayEventView(
                                        event: event,
                                        pointsPerHour: effectivePointsPerHour,
                                        maxVisibleHeight: coveredTextHeights[index]
                                    )
                                }
                                .eventuallyDateIntervalLayout(DateInterval(start: event.startDate, end: event.endDate))
                            }
                        }
                        .padding(.leading, Self.Constants.leadingInset + IKPadding.medium)
                        .padding(.trailing, value: .medium)
                        .padding(.vertical, Self.Constants.verticalInset - DayTimelineView.Constants.indexHeight / 2)

                        if calendar.isDate(date, inSameDayAs: timeline.date) {
                            let timeIndicatorPosition = timeIndicatorPosition(at: timeline.date)
                            TimelineIndicatorView(date: timeline.date)
                                .padding(.leading, value: .medium)
                                .visualEffect { content, proxy in
                                    content
                                        .offset(y: -proxy.size.height / 2 + timeIndicatorPosition)
                                }
                        }
                    }
                    .frame(height: viewHeight)
                }
                .contentMargins(.vertical, IKPadding.medium, for: .scrollContent)
                .scrollPosition($scrollPosition)
                .onScrollGeometryChange(for: CGFloat.self) { scrollProxy in
                    return scrollProxy.contentOffset.y + scrollProxy.contentInsets.top
                } action: { _, newValue in
                    scrollOffset = newValue

                    guard mainViewState.selectedDate == date else { return }
                    storedScrollPosition = Double(newValue)
                }
                .onAppear {
                    scrollToCorrectPosition(proxy)
                }
                .dayViewZoom(
                    pointsPerHour: $pointsPerHour,
                    currentMagnification: $currentMagnification,
                    scrollPosition: $scrollPosition,
                    date: date,
                    scrollOffset: scrollOffset,
                    maximumElapsedHours: CGFloat(hourMarks.count - 1)
                )
                .modifier(GlassHeaderBarModifier(miniCalendarHeight: miniCalendarHeight) {
                    DayHeaderView(selectedEvent: $selectedEvent, events: events.filter(\.isAllDay), date: date)
                })
            }
        }
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

    private func horizontalLayoutPointsPerHour(
        for livePointsPerHour: CGFloat
    ) -> CGFloat {
        guard Self.Constants.PointsPerHour.horizontalRelayoutStep > 0 else {
            return livePointsPerHour
        }

        let stepIndex = ((livePointsPerHour - Self.Constants.PointsPerHour.minimum) /
            Self.Constants.PointsPerHour.horizontalRelayoutStep)
            .rounded(.toNearestOrAwayFromZero)
        let snappedValue = Self.Constants.PointsPerHour.minimum + stepIndex *
            Self.Constants.PointsPerHour.horizontalRelayoutStep

        return min(max(snappedValue, Self.Constants.PointsPerHour.minimum),
                   Self.Constants.PointsPerHour.maximum)
    }
}

struct GlassHeaderBarModifier<BarContent: View>: ViewModifier {
    @State private var dayHeaderHeight: CGFloat = 0

    let miniCalendarHeight: CGFloat
    @ViewBuilder let barContent: () -> BarContent

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .scrollEdgeEffectStyle(.hard, for: .top)
                .safeAreaBar(edge: .top) {
                    Color.clear
                        .frame(height: miniCalendarHeight + dayHeaderHeight)
                        .glassEffect(.identity, in: Rectangle())
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .top) {
                    barContent()
                        .padding(.horizontal, value: .medium)
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.height
                        } action: { newHeight in
                            guard dayHeaderHeight != newHeight else { return }
                            dayHeaderHeight = newHeight
                        }
                        .padding(.top, miniCalendarHeight)
                }
        } else {
            content.safeAreaInset(edge: .top) {
                barContent()
                    .padding(.horizontal, value: .medium)
                    .background(Material.bar)
            }
        }
    }
}

#Preview {
    DayContentView(
        date: .now,
        events: [.preview, .preview],
        miniCalendarHeight: 0
    )
    .environment(MainViewState())
}
