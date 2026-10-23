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
import SwiftUI

struct MultipleDaysAllDayEventsView: View {
    @Environment(\.calendar) private var calendar

    @ScaledMetric(relativeTo: .caption) private var eventTitleLineHeight: CGFloat = 16

    let layout: MultipleDaysLayout
    let events: [Date: [UIEventSummary]]
    let visibleRowCount: Int
    let pagerScrollSync: CalendarPeriodPagerScrollSync

    private var allDayListMetrics: AllDayEventsListMetrics {
        AllDayEventsListMetrics(eventTitleLineHeight: eventTitleLineHeight)
    }

    var body: some View {
        if visibleRowCount > 0 {
            HStack(alignment: .top, spacing: 0) {
                AllDayLabelView()

                CalendarPeriodPagerMirror(scrollSync: pagerScrollSync, viewCount: layout.pagerViewCount) { pagerDate in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(layout.pageDates(for: pagerDate, calendar: calendar), id: \.self) { day in
                            dayColumn(events: events[calendar.startOfDay(for: day)] ?? [])
                        }
                    }
                }
                .frame(height: allDayListMetrics.listHeight(rowCount: visibleRowCount))
            }
            .padding(.leading, value: .medium)
            .padding(.bottom, IKPadding.micro)
        }
    }

    private func dayColumn(events: [UIEventSummary]) -> some View {
        ScrollView {
            LazyVStack(spacing: IKPadding.micro) {
                ForEach(events) { event in
                    AllDayEventButton(event: event)
                }
            }
        }
        .scrollDisabled(!allDayListMetrics.isScrollable(rowCount: events.count))
        .scrollIndicators(.hidden)
        .padding(.horizontal, MultipleDaysColumnView.Constants.eventsSpacing)
        .frame(maxWidth: .infinity, maxHeight: allDayListMetrics.listHeight(rowCount: visibleRowCount), alignment: .top)
    }
}

#Preview {
    @Previewable @State var pagerScrollSync = CalendarPeriodPagerScrollSync()
    MultipleDaysAllDayEventsView(
        layout: .week,
        events: [Calendar.current.startOfDay(for: .now): [.preview, .shortPreview]],
        visibleRowCount: 2,
        pagerScrollSync: pagerScrollSync
    )
}
