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

struct FullDayEventView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let events: [CalendarCoreUI.UIEvent]
    let date: Date

    private var visibleRowCount: Int {
        min(eventPairs.count, 2)
    }

    private var rowHeight: CGFloat {
        return 15.0 + DayView.Constants.verticalInset * 2
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
            Text(date, format: .dateTime.weekday().day().month().year())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(IKPadding.mini)
            HStack(alignment: .top, spacing: 0) {
                if !events.isEmpty {
                    Text("Jour entier")
                        .font(.caption2)
                        .padding(.leading, IKPadding.medium)
                        .frame(
                            width: DayView.Constants.leadingInset,
                            alignment: .leading
                        )
                    ScrollView {
                        VStack {
                            ForEach(eventPairs, id: \.0.id) { firstEvent, secondEvent in
                                HStack {
                                    Text(firstEvent.title)
                                        .lineLimit(1)
                                        .padding(.leading, IKPadding.mini)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .eventCellStyle(event: firstEvent, padding: 0)

                                    if let secondEvent = secondEvent {
                                        Text(secondEvent.title)
                                            .lineLimit(1)
                                            .padding(.leading, IKPadding.mini)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .eventCellStyle(event: secondEvent, padding: 0)
                                    }
                                }
                            }
                        }
                    }
                    .scrollDisabled(eventPairs.count <= 2)
                    .frame(height: CGFloat(visibleRowCount) * rowHeight)
                    .contentMargins(.bottom, IKPadding.micro, for: .scrollContent)
                    .contentMargins(.top, 0, for: .scrollContent)
                }
            }
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.color.borderDim2Default)
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.color.borderDim2Default)
                .frame(height: 1)
        }
    }
}
