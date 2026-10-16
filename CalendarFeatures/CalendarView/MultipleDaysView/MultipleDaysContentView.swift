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

    @State private var scrollPosition = ScrollPosition()
    @State private var scrollOffset = CGFloat.zero
    @State private var hasPerformedInitialScroll = false

    let layout: MultipleDaysLayout
    let events: [Date: [UIEventSummary]]
    let pagerScrollSync: CalendarPeriodPagerScrollSync

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
                        MultipleDaysColumnView(
                            date: day,
                            events: events(for: day),
                            pointsPerHour: geometry.pointsPerHour,
                            horizontalLayoutPointsPerHour: geometry.horizontalLayoutPointsPerHour
                        )
                    }
                }
            }
            .overlay(alignment: .leading) {
                MultipleDaysColumnView.Separator()
            }
            .onAppear {
                scrollToInitialPosition(geometry)
            }
            .onChange(of: geometry.visibleHeight) { oldHeight, newHeight in
                guard oldHeight == 0, newHeight > 0 else { return }
                scrollToInitialPosition(geometry)
            }
        } overlay: { geometry in
            TimelineView(.everyMinute) { timeline in
                CalendarPeriodPagerMirror(scrollSync: pagerScrollSync, viewCount: layout.pagerViewCount) { date in
                    HStack(spacing: 0) {
                        ForEach(layout.pageDates(for: date, calendar: calendar), id: \.self) { day in
                            TimelineIndicatorView()
                                .opacity(calendar.isDate(day, inSameDayAs: timeline.date) ? 1 : 0)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, IKPadding.medium + TimelineBackgroundView.Constants.leadingInset)
                .visualEffect { content, proxy in
                    content.offset(y: geometry.yPosition(for: timeline.date, calendar: calendar) - proxy.size.height / 2)
                }
            }
        }
        .onChange(of: scrollOffset) { _, newValue in
            UserDefaults.shared.dayViewScrollPosition = newValue
        }
    }

    private func events(for date: Date) -> [UIEventSummary] {
        return events[calendar.startOfDay(for: date)] ?? []
    }

    private func scrollToInitialPosition(_ geometry: TimelineGeometry) {
        guard !hasPerformedInitialScroll else { return }

        if layout.isSelectingToday(selectedDate, calendar: calendar) {
            guard geometry.visibleHeight > 0 else { return }
            scrollPosition.scrollTo(y: geometry.centeredScrollOffset(for: .now, calendar: calendar))
        } else {
            scrollPosition.scrollTo(y: UserDefaults.shared.dayViewScrollPosition)
        }
        hasPerformedInitialScroll = true
    }
}

#Preview {
    @Previewable @State var selectedDate = Date.now
    @Previewable @State var pagerScrollSync = CalendarPeriodPagerScrollSync()
    MultipleDaysContentView(layout: .week, events: [:], pagerScrollSync: pagerScrollSync, selectedDate: $selectedDate)
}
