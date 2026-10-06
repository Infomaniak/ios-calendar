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

import CalendarCore
import CalendarCoreUI
import DesignSystem
import ESDSFoundation
import Eventually
import SwiftUI

struct DayView: View {
    @Environment(\.calendar) private var calendar
    @Environment(DaysViewModel.self) private var daysViewModel

    let date: Date

    var body: some View {
        DayContentView(
            date: date,
            events: daysViewModel.events(for: date, calendar: calendar)
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
    @Environment(\.esdsTheme) private var theme
    @Environment(MainViewState.self) private var mainViewState

    @SceneStorage("DayViewScrollPosition") private var storedScrollPosition = 0.0
    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset: CGFloat = 0

    @State private var pointsPerHour = Constants.PointsPerHour.default
    @State private var currentMagnification: CGFloat = 1.0
    @State private var coveredTextHeights: [Int: CGFloat] = [:]
    @State private var draggedEventStartDate: Date?

    let date: Date
    let events: [CalendarCoreUI.UIEvent]

    private var hourMarks: [Date] {
        let startOfDay = calendar.startOfDay(for: date)
        guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        var marks = [Date]()
        var currentMark = startOfDay
        while currentMark < startOfNextDay {
            marks.append(currentMark)
            guard let nextMark = calendar.date(byAdding: .hour, value: 1, to: currentMark) else { break }
            currentMark = nextMark
        }

        marks.append(startOfNextDay)

        return marks
    }

    private var allDayEvents: [CalendarCoreUI.UIEvent] {
        return events.filter(\.isAllDay)
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
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard location.x >= Self.Constants.leadingInset,
                                  let startDate = Self.eventStartDate(
                                      at: location.y,
                                      on: date,
                                      pointsPerHour: effectivePointsPerHour,
                                      calendar: calendar
                                  ) else { return }
                            startEventCreation(at: startDate)
                        }
                        .gesture(EventCreationLongPressGesture { phase, location in
                            handleEventCreationLongPress(phase: phase, location: location)
                        })
                        .padding(.horizontal, value: .medium)

                        if let startDate = draggedEventStartDate {
                            eventCreationPlaceholder(startDate: startDate)
                        } else if mainViewState.isShowingEventCreation,
                                  let startDate = mainViewState.eventCreationStartDate,
                                  calendar.isDate(startDate, inSameDayAs: date) {
                            eventCreationPlaceholder(startDate: startDate)
                        }

                        EventuallyLayout(
                            startOfDay: calendar.startOfDay(for: date),
                            hourSlotHeight: effectivePointsPerHour,
                            horizontalHourSlotHeight: horizontalPointsPerHour,
                            config: .init(
                                hSpacing: Constants.layoutHorizontalSpacing,
                                vSpacing: Constants.layoutVerticalSpacing
                            )
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
                                .allowsHitTesting(false)
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
                .onChange(of: mainViewState.selectedDate) { oldSelectedDate, selectedDate in
                    guard calendar.isDate(date, inSameDayAs: selectedDate),
                          !calendar.isDate(date, inSameDayAs: oldSelectedDate) else { return }
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
            }
        }
        .additionalSafeAreaBarView(
            id: date,
            version: allDayEvents,
            isActive: calendar.isDate(date, inSameDayAs: mainViewState.selectedDate)
        ) {
            DayHeaderView(events: allDayEvents, date: date)
                .padding(.horizontal, value: .medium)
        }
    }

    private func timeIndicatorPosition(at date: Date) -> CGFloat {
        let elapsedTime = date.timeIntervalSince(calendar.startOfDay(for: date)) / 3600
        return elapsedTime * effectivePointsPerHour + Self.Constants.verticalInset
    }

    private func handleEventCreationLongPress(phase: EventCreationLongPressGesture.Phase, location: CGPoint) {
        switch phase {
        case .began:
            guard location.x >= Self.Constants.leadingInset else { return }
            draggedEventStartDate = eventStartDate(at: location.y)
        case .changed:
            guard let previousStartDate = draggedEventStartDate else { return }
            draggedEventStartDate = eventStartDate(at: location.y) ?? previousStartDate
        case .ended:
            guard let startDate = draggedEventStartDate else { return }
            draggedEventStartDate = nil
            startEventCreation(at: startDate)
        case .cancelled:
            draggedEventStartDate = nil
        }
    }

    private func eventStartDate(at verticalPosition: CGFloat) -> Date? {
        Self.eventStartDate(
            at: verticalPosition,
            on: date,
            pointsPerHour: effectivePointsPerHour,
            calendar: calendar
        )
    }

    private func startEventCreation(at startDate: Date) {
        mainViewState.eventCreationStartDate = startDate
        mainViewState.isShowingEventCreation = true
    }

    private func eventCreationPlaceholder(startDate: Date) -> some View {
        let startOfDay = calendar.startOfDay(for: date)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startDate
        let endDate = min(
            startDate.addingTimeInterval(UserDefaults.shared.defaultEventDuration.timeInterval),
            startOfNextDay
        )
        let startPosition = startDate.timeIntervalSince(startOfDay) / 3600 * effectivePointsPerHour
        let height = endDate.timeIntervalSince(startDate) / 3600 * effectivePointsPerHour

        return RoundedRectangle(cornerRadius: IKRadius.small)
            .fill(theme.color.backgroundDatavizGrayDim1.opacity(0.25))
            .frame(height: max(height - 2 * Constants.layoutVerticalSpacing, 0))
            .padding(.leading, Self.Constants.leadingInset + IKPadding.medium)
            .padding(.trailing, value: .medium)
            .offset(y: startPosition + Self.Constants.verticalInset + Constants.layoutVerticalSpacing)
            .allowsHitTesting(false)
    }

    static func eventStartDate(
        at verticalPosition: CGFloat,
        on date: Date,
        pointsPerHour: CGFloat,
        calendar: Calendar
    ) -> Date? {
        let elapsedMinutes = ((verticalPosition - Constants.verticalInset) / pointsPerHour * 12).rounded(.up) * 5
        let startOfDay = calendar.startOfDay(for: date)
        let startDate = startOfDay.addingTimeInterval(elapsedMinutes * 60)
        guard verticalPosition >= Constants.verticalInset,
              calendar.isDate(startDate, inSameDayAs: date) else { return nil }
        return startDate
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

#Preview {
    DayContentView(
        date: .now,
        events: [.preview, .preview]
    )
    .environment(MainViewState())
}

struct EventCreationLongPressGesture: UIGestureRecognizerRepresentable {
    enum Phase {
        case began
        case changed
        case ended
        case cancelled
    }

    let action: (Phase, CGPoint) -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = 0.3
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        let location = context.converter.localLocation
        switch recognizer.state {
        case .began:
            action(.began, location)
        case .changed:
            action(.changed, location)
        case .ended:
            action(.ended, location)
        case .cancelled, .failed:
            action(.cancelled, location)
        default:
            break
        }
    }
}
