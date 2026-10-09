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

    let events: [CalendarCoreUI.UIEvent]
    let date: Date

    private static let maxVisibleRows = 2

    private var eventPairs: [(CalendarCoreUI.UIEvent, CalendarCoreUI.UIEvent?)] {
        stride(from: 0, to: events.count, by: 2).map { index in
            let secondEvent = index + 1 < events.count ? events[index + 1] : nil
            return (events[index], secondEvent)
        }
    }

    private var isAllDayListScrollable: Bool {
        eventPairs.count > Self.maxVisibleRows
    }

    /// Fixed height of the all-day list: the visible rows plus, when scrollable, a peek of the next row.
    private var allDayListHeight: CGFloat {
        let rowHeight = eventTitleLineHeight + IKPadding.mini * 2
        let visibleRowCount = CGFloat(min(eventPairs.count, Self.maxVisibleRows))
        let rowsHeight = visibleRowCount * rowHeight + (visibleRowCount - 1) * IKPadding.micro
        let peekHeight = isAllDayListScrollable ? IKPadding.micro + IKPadding.mini : 0
        return rowsHeight + peekHeight
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
                    Text(CalendarResourcesStrings.allDayLabel)
                        .font(.caption2)
                        .foregroundStyle(theme.color.contentTertiary)
                        .padding(.trailing, value: .small)
                        .frame(width: TimelineBackgroundView.Constants.leadingInset, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    ScrollView {
                        LazyVStack(spacing: IKPadding.micro) {
                            ForEach(eventPairs, id: \.0.id) { firstEvent, secondEvent in
                                HStack(spacing: IKPadding.micro) {
                                    EventDetailsPopoverButton(event: firstEvent) {
                                        Text(firstEvent.displayTitle)
                                            .allDayEventStyle(for: firstEvent)
                                    }

                                    if let secondEvent {
                                        EventDetailsPopoverButton(event: secondEvent) {
                                            Text(secondEvent.displayTitle)
                                                .allDayEventStyle(for: secondEvent)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .scrollDisabled(!isAllDayListScrollable)
                    .scrollIndicators(isAllDayListScrollable ? .automatic : .hidden)
                    .frame(height: allDayListHeight)
                }
                .padding(.bottom, IKPadding.micro)
            }
        }
        .padding(.top, IKPadding.medium)
        .padding(.bottom, events.isEmpty ? IKPadding.mini : 0)
    }
}

private extension View {
    func allDayEventStyle(for event: CalendarCoreUI.UIEvent) -> some View {
        font(.caption.bold())
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .eventCellStyle(event: event)
    }
}
