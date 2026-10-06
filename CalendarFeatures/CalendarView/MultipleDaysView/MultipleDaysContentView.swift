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
import SwiftUI

struct MultipleDaysContentView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset = CGFloat.zero
    @State private var pagerScrollSync = CalendarPeriodPagerScrollSync()

    let layout: MultipleDaysLayout
    let events: [Date: [CalendarCoreUI.UIEvent]]

    @Binding var selectedDate: Date

    private var pagerDate: Binding<Date> {
        Binding {
            layout.pagerDate(for: selectedDate, calendar: calendar)
        } set: { newPagerDate in
            guard !calendar.isDate(newPagerDate, equalTo: selectedDate, toGranularity: layout.pagerComponent) else { return }
            selectedDate = newPagerDate
        }
    }

    var body: some View {
        TimelineContentView(
            scrollPosition: $scrollPosition,
            scrollOffset: $scrollOffset,
            date: selectedDate,
            trailingPadding: 0
        ) { geometry in
            CalendarPeriodPager(
                component: layout.pagerComponent,
                periodOffsets: layout.pagerOffsets,
                viewCount: layout.pagerViewCount,
                scrollBehavior: layout.pagerScrollBehavior,
                scrollSync: pagerScrollSync,
                date: pagerDate
            ) { date in
                HStack(spacing: 0) {
                    ForEach(layout.pageDates(for: date, calendar: calendar), id: \.self) { day in
                        MultipleDaysColumnView(date: day, events: events(for: day), pointsPerHour: geometry.pointsPerHour)
                    }
                }
            }
            .overlay(alignment: .leading) {
                MultipleDaysColumnView.Separator()
            }
            .onAppear {
                scrollToCorrectPosition(geometry)
            }
            .onChange(of: selectedDate) { oldSelectedDate, newSelectedDate in
                guard layout.isSelectingToday(newSelectedDate, calendar: calendar),
                      !layout.isSelectingToday(oldSelectedDate, calendar: calendar) else { return }
                scrollToCorrectPosition(geometry)
            }
        } overlay: { _ in
            // Nothing yet
        }
        .onChange(of: scrollOffset) { _, newValue in
            UserDefaults.shared.dayViewScrollPosition = newValue
        }
        .additionalSafeAreaBarView(id: layout, version: calendar.component(.weekOfYear, from: selectedDate)) {
            MultipleDaysHeaderView(layout: layout, date: selectedDate, pagerScrollSync: pagerScrollSync)
        }
    }

    private func events(for date: Date) -> [CalendarCoreUI.UIEvent] {
        guard let events = events[calendar.startOfDay(for: date)] else { return [] }
        return events.filter { !$0.isAllDay }
    }

    private func scrollToCorrectPosition(_ geometry: TimelineGeometry) {
        if layout.isSelectingToday(selectedDate, calendar: calendar) {
            let timeOfDay = Date.now.timeIntervalSince(calendar.startOfDay(for: .now))
            scrollPosition.scrollTo(y: geometry.centeredScrollOffset(for: geometry.startOfDay.addingTimeInterval(timeOfDay)))
        } else {
            scrollPosition.scrollTo(y: UserDefaults.shared.dayViewScrollPosition)
        }
    }
}

#Preview {
    @Previewable @State var selectedDate = Date.now
    MultipleDaysContentView(layout: .week, events: [:], selectedDate: $selectedDate)
}
