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
import ESDSFoundation
import Eventually
import SwiftUI

struct MultipleDaysColumnView: View {
    enum Constants {
        static let eventsSpacing: CGFloat = 2
    }

    struct Separator: View {
        @Environment(\.esdsTheme) private var theme

        var body: some View {
            Rectangle()
                .fill(theme.color.borderDim2)
                .frame(width: TimelineBackgroundView.Constants.indexHeight)
                .frame(maxHeight: .infinity)
        }
    }

    @Environment(\.calendar) private var calendar

    @State private var coveredTextHeights: [Int: CGFloat] = [:]

    let date: Date
    let events: [CalendarCoreUI.UIEvent]
    let pointsPerHour: CGFloat

    var body: some View {
        EventuallyLayout(
            startOfDay: calendar.startOfDay(for: date),
            hourSlotHeight: pointsPerHour,
            config: .init(
                hSpacing: Constants.eventsSpacing,
                vSpacing: DayContentView.Constants.layoutVerticalSpacing
            ),
            onCoveredIndicesChange: onCoveredIndicesChange
        ) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                EventDetailsPopoverButton(event: event) {
                    DayEventView(
                        event: event,
                        pointsPerHour: pointsPerHour,
                        maxVisibleHeight: coveredTextHeights[index]
                    )
                }
                .eventuallyDateIntervalLayout(DateInterval(start: event.startDate, end: event.endDate))
            }
        }
        .padding(.horizontal, Constants.eventsSpacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .trailing) {
            Separator()
        }
    }

    private func onCoveredIndicesChange(textHeights: [Int: CGFloat]) {
        guard coveredTextHeights != textHeights else { return }
        coveredTextHeights = textHeights
    }
}

#Preview {
    MultipleDaysColumnView(date: .now, events: [.preview, .shortPreview], pointsPerHour: 64)
}
