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
    @Environment(\.esdsTheme) private var theme

    let events: [CalendarCoreUI.UIEvent]
    let date: Date

    @State private var isShowingAllEvents = false

    private static let maxVisibleRows = 2

    private var visibleEventPairs: [(CalendarCoreUI.UIEvent, CalendarCoreUI.UIEvent?)] {
        Self.pairs(of: Array(events.prefix(Self.maxVisibleRows * 2)))
    }

    private var hiddenEventCount: Int {
        max(events.count - Self.maxVisibleRows * 2, 0)
    }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Text(CalendarResourcesStrings.weekHeaderWeekNumber(
                    Calendar.current.component(.weekOfYear, from: date)
                ))
                .font(.caption2)
                .foregroundStyle(theme.color.contentTertiary)
                .padding(.trailing, value: .small)
                .frame(width: DayContentView.Constants.leadingInset, alignment: .trailing)

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
                    VStack(alignment: .trailing, spacing: IKPadding.micro) {
                        Text(CalendarResourcesStrings.allDayLabel)
                            .font(.caption2)
                            .foregroundStyle(theme.color.contentTertiary)
                            .multilineTextAlignment(.trailing)

                        if hiddenEventCount > 0 {
                            Button {
                                isShowingAllEvents = true
                            } label: {
                                Text(hiddenEventCount, format: .number.sign(strategy: .always()))
                                    .font(.caption.bold())
                                    .foregroundStyle(theme.color.contentSecondary)
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $isShowingAllEvents) {
                                AllDayEventsPopoverView(events: events)
                            }
                        }
                    }
                    .padding(.trailing, value: .small)
                    .frame(width: DayContentView.Constants.leadingInset, alignment: .trailing)

                    AllDayEventRows(eventPairs: visibleEventPairs)
                }
                .padding(.bottom, IKPadding.micro)
            }
        }
        .padding(.bottom, events.isEmpty ? IKPadding.mini : 0)
    }
}

extension DayHeaderView {
    static func pairs(of events: [CalendarCoreUI.UIEvent]) -> [(CalendarCoreUI.UIEvent, CalendarCoreUI.UIEvent?)] {
        stride(from: 0, to: events.count, by: 2).map { index in
            let secondEvent = index + 1 < events.count ? events[index + 1] : nil
            return (events[index], secondEvent)
        }
    }
}

private struct AllDayEventRows: View {
    let eventPairs: [(CalendarCoreUI.UIEvent, CalendarCoreUI.UIEvent?)]

    var body: some View {
        VStack(spacing: IKPadding.micro) {
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
}

private struct AllDayEventsPopoverView: View {
    let events: [CalendarCoreUI.UIEvent]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IKPadding.micro) {
                ForEach(events, id: \.id) { event in
                    EventDetailsPopoverButton(event: event) {
                        Text(event.displayTitle)
                            .allDayEventStyle(for: event)
                    }
                }
            }
            .padding(value: .medium)
        }
        .selfSizingPopover(idealWidth: 320)
        .presentationCompactAdaptation(.popover)
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
