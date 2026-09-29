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
import ESDSFoundation
import Eventually
import SwiftUI

struct WeekView: View {
    @Environment(\.calendar) private var calendar
    @Environment(WeeksViewModel.self) private var weeksViewModel

    let date: Date

    var body: some View {
        WeekContentView(date: date, events: weeksViewModel.events(forWeekOf: date, calendar: calendar))
    }
}

struct WeekContentView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset = CGFloat.zero

    @State private var coveredTextHeights: [Date: [Int: CGFloat]] = [:]

    let date: Date
    let events: [Date: [CalendarCoreUI.UIEvent]]

    private var weekDates: [Date] {
        let weekStart = calendar.weekStart(for: date)
        return (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        TimelineContentView(
            scrollPosition: $scrollPosition,
            scrollOffset: $scrollOffset,
            date: date
        ) { geometry in
            HStack(spacing: 2) {
                ForEach(Array(weekDates.enumerated()), id: \.element) { _, weekDate in
                    Divider()
                        .overlay(theme.color.borderDim2)

                    dayEventsLayout(for: weekDate, geometry: geometry)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Divider()
                    .overlay(theme.color.borderDim2)
            }
        } overlay: { _ in
            EmptyView()
        }
    }

    private func dayEventsLayout(for weekDate: Date, geometry: TimelineGeometry) -> some View {
        let startOfDay = calendar.startOfDay(for: weekDate)
        let dayEvents = (events[startOfDay] ?? []).filter { !$0.isAllDay }
        let coveredIndicesHandler: @MainActor @Sendable ([Int: CGFloat]) -> Void = { textHeights in
            onCoveredIndicesChange(for: startOfDay, textHeights: textHeights)
        }

        return EventuallyLayout(
            startOfDay: startOfDay,
            hourSlotHeight: geometry.pointsPerHour,
            config: .init(
                hSpacing: 2,
                vSpacing: DayContentView.Constants.layoutVerticalSpacing
            ),
            onCoveredIndicesChange: coveredIndicesHandler
        ) {
            ForEach(Array(dayEvents.enumerated()), id: \.element.id) { index, event in
                EventDetailsPopoverButton(event: event) {
                    DayEventView(
                        event: event,
                        pointsPerHour: geometry.pointsPerHour,
                        maxVisibleHeight: coveredTextHeights[startOfDay]?[index]
                    )
                }
                .eventuallyDateIntervalLayout(DateInterval(start: event.startDate, end: event.endDate))
            }
        }
    }

    private func onCoveredIndicesChange(for startOfDay: Date, textHeights: [Int: CGFloat]) {
        guard coveredTextHeights[startOfDay] != textHeights else { return }
        coveredTextHeights[startOfDay] = textHeights
    }
}

#Preview {
    WeekContentView(date: .now, events: [:])
}
