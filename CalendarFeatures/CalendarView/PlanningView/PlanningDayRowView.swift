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

struct PlanningDayRowView: View {
    @Environment(\.calendar) private var calendar

    @ScaledMetric(relativeTo: .title3) private var dayHeaderSize: CGFloat = 64

    let date: Date
    let events: [UIEventSummary]

    private var isWeekStart: Bool {
        calendar.component(.weekday, from: date) == calendar.firstWeekday
    }

    var body: some View {
        VStack(spacing: IKPadding.mini) {
            if isWeekStart {
                PlanningWeekHeaderView(date: date)
            }

            if events.isEmpty {
                NoEventsCellView()
            } else {
                ForEach(events) { event in
                    VStack {
                        EventDetailsPopoverButton(event: event) {
                            if event.isAllDay {
                                PlanningDayEventView(event: event)
                            } else {
                                PlanningEventView(event: event)
                            }
                        }
                        .eventQuickActions(.menu, event: event)
                    }
                }
            }
        }
        .padding(.leading, dayHeaderSize)
        .padding(.trailing, value: .mini)
        .frame(minHeight: dayHeaderSize, alignment: .top)
        .overlay(alignment: .topLeading) {
            PlanningDayHeaderView(date: date)
                .frame(maxHeight: .infinity, alignment: .top)
                .visualEffect { [dayHeaderSize] content, proxy in
                    let frame = proxy.frame(in: .scrollView)
                    let maxOffset = max(0, frame.height - dayHeaderSize)
                    let offset = min(max(0, -frame.minY), maxOffset)
                    return content.offset(y: offset)
                }
        }
        .padding(.vertical, value: .medium)
    }
}

#Preview {
    ScrollView {
        PlanningDayRowView(date: Date(), events: [.shortPreview, .mediumPreview, .longPreview])
        PlanningDayRowView(date: Date().addingTimeInterval(86400), events: [])
    }
    .environment(MainViewState())
    .environment(EventInteractionModel())
}
