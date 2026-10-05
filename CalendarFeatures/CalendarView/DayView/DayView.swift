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

        static let horizontalRelayoutStep: CGFloat = 8
    }

    @Environment(\.calendar) private var calendar
    @Environment(MainViewState.self) private var mainViewState

    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset = CGFloat.zero

    @State private var coveredTextHeights: [Int: CGFloat] = [:]

    let date: Date
    let events: [CalendarCoreUI.UIEvent]

    private var allDayEvents: [CalendarCoreUI.UIEvent] {
        return events.filter(\.isAllDay)
    }

    private var isSelected: Bool {
        return calendar.isDate(date, inSameDayAs: mainViewState.selectedDate)
    }

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            TimelineContentView(scrollPosition: $scrollPosition, scrollOffset: $scrollOffset, date: date) { geometry in
                EventuallyLayout(
                    startOfDay: geometry.startOfDay,
                    hourSlotHeight: geometry.pointsPerHour,
                    horizontalHourSlotHeight: horizontalLayoutPointsPerHour(for: geometry.pointsPerHour),
                    config: .init(hSpacing: Constants.layoutHorizontalSpacing, vSpacing: Constants.layoutVerticalSpacing),
                    onCoveredIndicesChange: onCoveredIndicesChange
                ) {
                    ForEach(Array(events.filter { !$0.isAllDay }.enumerated()), id: \.element.id) { index, event in
                        EventDetailsPopoverButton(event: event) {
                            DayEventView(
                                event: event,
                                pointsPerHour: geometry.pointsPerHour,
                                maxVisibleHeight: coveredTextHeights[index]
                            )
                        }
                        .eventuallyDateIntervalLayout(DateInterval(start: event.startDate, end: event.endDate))
                    }
                }
                .onAppear {
                    scrollToCorrectPosition(geometry)
                }
                .onChange(of: mainViewState.selectedDate) { oldSelectedDate, selectedDate in
                    guard calendar.isDate(date, inSameDayAs: selectedDate),
                          !calendar.isDate(date, inSameDayAs: oldSelectedDate) else { return }
                    scrollToCorrectPosition(geometry)
                }
            } overlay: { geometry in
                timelineIndicator(date: timeline.date, geometry: geometry)
            }
            .onChange(of: scrollOffset) { _, newValue in
                guard isSelected else { return }
                UserDefaults.shared.dayViewScrollPosition = newValue
            }
        }
        .additionalSafeAreaBarView(id: date, version: allDayEvents, isActive: isSelected) {
            DayHeaderView(events: allDayEvents, date: date)
                .padding(.horizontal, value: .medium)
        }
    }

    @ViewBuilder
    private func timelineIndicator(date: Date, geometry: TimelineGeometry) -> some View {
        if calendar.isDate(self.date, inSameDayAs: date) {
            TimelineIndicatorView(date: date)
                .padding(.leading, value: .medium)
                .visualEffect { content, proxy in
                    content
                        .offset(y: -proxy.size.height / 2 + geometry.yPosition(for: date))
                }
        }
    }

    private func onCoveredIndicesChange(textHeights: [Int: CGFloat]) {
        guard coveredTextHeights != textHeights else { return }
        coveredTextHeights = textHeights
    }

    private func scrollToCorrectPosition(_ geometry: TimelineGeometry) {
        guard geometry.visibleHeight > 0 else { return }

        if calendar.isDate(date, inSameDayAs: .now) {
            scrollPosition.scrollTo(y: geometry.centeredScrollOffset(for: .now))
        } else {
            scrollPosition.scrollTo(y: UserDefaults.shared.dayViewScrollPosition)
        }
    }

    private func horizontalLayoutPointsPerHour(for livePointsPerHour: CGFloat) -> CGFloat {
        guard Self.Constants.horizontalRelayoutStep > 0 else {
            return livePointsPerHour
        }

        let stepIndex = ((livePointsPerHour - TimelineViewConstants.PointsPerHour.minimum) /
            Self.Constants.horizontalRelayoutStep)
            .rounded(.toNearestOrAwayFromZero)
        let snappedValue = TimelineViewConstants.PointsPerHour.minimum + stepIndex * Self.Constants.horizontalRelayoutStep

        return min(max(snappedValue, TimelineViewConstants.PointsPerHour.minimum), TimelineViewConstants.PointsPerHour.maximum)
    }
}

#Preview {
    DayContentView(date: .now, events: [.preview, .preview])
        .environment(MainViewState())
}
