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
import SwiftUI

struct FullDayEventView: View {
    @Environment(\.esdsTheme) private var theme

    let events: [CalendarCoreUI.UIEvent]
    let date: Date

    private var visibleRowCount: Int {
        min(eventPairs.count, 2)
    }

    private var headerHeight: CGFloat {
        let rowHeight = 16 + DayView.Constants.verticalInset * 2 + IKPadding.mini
        let extraPadding = eventPairs.count > 2 ? IKPadding.mini : 0
        return CGFloat(visibleRowCount) * rowHeight + extraPadding
    }

    private var eventPairs: [(CalendarCoreUI.UIEvent, CalendarCoreUI.UIEvent?)] {
        stride(from: 0, to: events.count, by: 2).map { index in
            let firstEvent = events[index]
            let secondEvent = (index + 1 < events.count) ? events[index + 1] : nil
            return (firstEvent, secondEvent)
        }
    }

    var body: some View {
        VStack {
            HStack {
                let weekNumber = Calendar.current.component(.weekOfYear, from: date)
                Text(CalendarResourcesStrings.weekHeaderWeekNumber(weekNumber))
                    .foregroundStyle(theme.color.contentTertiary)
                    .frame(
                        width: DayView.Constants.leadingInset,
                        alignment: .trailing
                    )

                (
                    Text(date, format: .dateTime.weekday(.wide))
                        .fontWeight(.semibold)
                        + Text(" – ")
                        + Text(date, format: .dateTime.day().month())
                )
                .font(.body)
                .foregroundStyle(theme.color.contentPrimary)
                .padding(.leading, IKPadding.mini)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .top, spacing: 0) {
                if !events.isEmpty {
                    Text(CalendarResourcesStrings.allDayLabel)
                        .font(.caption2)
                        .foregroundStyle(theme.color.contentTertiary)
                        .frame(
                            width: DayView.Constants.leadingInset,
                            alignment: .trailing
                        )
                        .multilineTextAlignment(.trailing)
                    ScrollView {
                        VStack(spacing: IKPadding.micro) {
                            ForEach(eventPairs, id: \.0.id) { firstEvent, secondEvent in
                                HStack(spacing: IKPadding.micro) {
                                    Text(firstEvent.title)
                                        .allDayEventStyle(for: firstEvent)

                                    if let secondEvent {
                                        Text(secondEvent.title)
                                            .allDayEventStyle(for: secondEvent)
                                    }
                                }
                            }
                        }
                    }
                    .scrollDisabled(eventPairs.count <= 2)
                    .frame(height: headerHeight)
                    .contentMargins(.bottom, IKPadding.micro, for: .scrollContent)
                    .contentMargins(.top, 0, for: .scrollContent)
                }
            }
        }
        .padding(.bottom, events.isEmpty ? IKPadding.medium : 0)
        .overlay(alignment: .bottom) {
            Divider()
                .frame(height: 1)
                .overlay(theme.color.borderDim2Default)
        }
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
