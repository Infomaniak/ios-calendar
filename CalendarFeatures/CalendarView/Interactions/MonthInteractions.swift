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
import ESDSFoundation
import SwiftUI

extension View {
    /// Makes a month week row a drop target and draws the placeholder of the event being moved or created.
    func monthWeekInteractions(days: [Date], metrics: MonthGridMetrics) -> some View {
        modifier(MonthWeekInteractionsModifier(days: days, metrics: metrics))
    }
}

private struct MonthWeekInteractionsModifier: ViewModifier {
    @Environment(\.calendar) private var calendar
    @Environment(EventInteractionModel.self) private var interaction

    let days: [Date]
    let metrics: MonthGridMetrics

    func body(content: Content) -> some View {
        content
            .overlay {
                MonthPlaceholderLayer(days: days, metrics: metrics)
                    .allowsHitTesting(false)
            }
            .onDrop(
                of: [.calendarEvent],
                delegate: MonthDropDelegate(
                    interaction: interaction,
                    calendar: calendar,
                    days: days,
                    columnWidth: metrics.columnWidth
                )
            )
    }
}

private struct MonthPlaceholderLayer: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme
    @Environment(EventInteractionModel.self) private var interaction

    let days: [Date]
    let metrics: MonthGridMetrics

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                ZStack(alignment: .top) {
                    if let placeholder = interaction.placeholder, calendar.isDate(placeholder.start, inSameDayAs: day) {
                        theme.color.backgroundBrand
                            .opacity(0.12)

                        EventPlaceholderView(placeholder: placeholder, style: .compact)
                            .frame(height: metrics.laneHeight)
                            .padding(.top, metrics.totalDayNumberHeight)
                            .padding(.horizontal, value: .micro)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.snappy(duration: 0.2), value: interaction.placeholder)
    }
}

private struct MonthDropDelegate: DropDelegate {
    let interaction: EventInteractionModel
    let calendar: Foundation.Calendar
    let days: [Date]
    let columnWidth: CGFloat

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.calendarEvent])
    }

    func dropEntered(info: DropInfo) {
        _ = hover(info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: hover(info) ? .move : .forbidden)
    }

    func dropExited(info: DropInfo) {
        interaction.hoverExited()
    }

    func performDrop(info: DropInfo) -> Bool {
        interaction.drop(info.itemProviders(for: [.calendarEvent]), calendar: calendar)
        return true
    }

    private func hover(_ info: DropInfo) -> Bool {
        guard !days.isEmpty, columnWidth > 0 else { return false }

        let column = min(max(Int(info.location.x / columnWidth), 0), days.count - 1)
        let day = days[column]
        return interaction.hover(day: day, proposedStart: day, isTimeline: false, calendar: calendar)
    }
}
