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
import CalendarResources
import DesignSystem
import ESDSFoundation
import SwiftUI

struct DayHeaderView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    @ScaledMetric(relativeTo: .caption) private var eventTitleLineHeight: CGFloat = 16

    let events: [UIEventSummary]
    let date: Date

    private var eventPairs: [(UIEventSummary, UIEventSummary?)] {
        stride(from: 0, to: events.count, by: 2).map { index in
            let secondEvent = index + 1 < events.count ? events[index + 1] : nil
            return (events[index], secondEvent)
        }
    }

    private var allDayListMetrics: AllDayEventsListMetrics {
        AllDayEventsListMetrics(eventTitleLineHeight: eventTitleLineHeight)
    }

    private var isAllDayListScrollable: Bool {
        allDayListMetrics.isScrollable(rowCount: eventPairs.count)
    }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Text(CalendarResourcesStrings.weekHeaderWeekNumber(calendar.component(.weekOfYear, from: date)))
                    .font(.caption2)
                    .foregroundStyle(theme.color.contentTertiary)
                    .padding(.trailing, value: .small)
                    .frame(width: TimelineBackgroundView.Constants.leadingInset, alignment: .trailing)

                HStack(spacing: 2) {
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(.footnote)
                        .fontWeight(.semibold)
                    Text("-")
                    Text(date, format: .dateTime.day().month())
                }
                .font(.caption)
                .foregroundStyle(theme.color.contentPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !events.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    AllDayLabelView()

                    ScrollView {
                        LazyVStack(spacing: IKPadding.micro) {
                            ForEach(eventPairs, id: \.0.id) { firstEvent, secondEvent in
                                HStack(spacing: IKPadding.micro) {
                                    AllDayEventButton(event: firstEvent)

                                    if let secondEvent {
                                        AllDayEventButton(event: secondEvent)
                                    }
                                }
                            }
                        }
                    }
                    .scrollDisabled(!isAllDayListScrollable)
                    .scrollIndicators(isAllDayListScrollable ? .automatic : .hidden)
                    .frame(height: allDayListMetrics.listHeight(rowCount: eventPairs.count))
                }
                .padding(.bottom, IKPadding.micro)
            }
        }
        .padding(.top, IKPadding.medium)
        .padding(.bottom, events.isEmpty ? IKPadding.mini : 0)
    }
}
