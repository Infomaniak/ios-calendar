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
import SwiftUI

extension View {
    /// Makes a day column of a timeline interactive: long press to create, drop to move, and draws the placeholder.
    ///
    /// Must be inside a `creationPage`, whose `y = 0` is the start of the day.
    func timelineInteractions(date: Date, pointsPerHour: CGFloat) -> some View {
        modifier(TimelineInteractionsModifier(date: date, pointsPerHour: pointsPerHour))
    }
}

private struct TimelineInteractionsModifier: ViewModifier {
    @Environment(\.calendar) private var calendar
    @Environment(\.timelineAutoScroller) private var autoScroller
    @Environment(\.creationPage) private var creationPage
    @Environment(EventInteractionModel.self) private var interaction

    let date: Date
    let pointsPerHour: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                Color.clear
                    .contentShape(.rect)
                    .creationGesture(action: handleCreationGesture)
            }
            .overlay {
                TimelinePlaceholderLayerView(date: date, pointsPerHour: pointsPerHour)
                    .allowsHitTesting(false)
            }
            .onDrop(
                of: [.calendarEvent],
                delegate: TimelineDropDelegate(
                    interaction: interaction,
                    autoScroller: autoScroller,
                    calendar: calendar,
                    date: date,
                    pointsPerHour: pointsPerHour
                )
            )
    }

    private func handleCreationGesture(phase: CreationGesturePhase, location: CGPoint) {
        // Days of a page share their vertical axis: the page's y is also the time in the day under the finger.
        let day = phase == .began ? date : creationPage?.day(at: location) ?? date
        let start = creationStart(atY: location.y, in: day)

        switch phase {
        case .began:
            interaction.beginCreation(at: start, calendar: calendar)
        case .changed:
            interaction.updateCreation(to: start)
            autoScroller?.update(eventLayerY: location.y) { [interaction] eventLayerY in
                interaction.updateCreation(to: creationStart(atY: eventLayerY, in: day))
            }
        case .ended:
            interaction.updateCreation(to: start)
            autoScroller?.stop()
            interaction.endCreation()
        case .cancelled:
            autoScroller?.stop()
            interaction.cancelCreation()
        }
    }

    private func creationStart(atY y: CGFloat, in day: Date) -> Date {
        let date = calendar.date(atY: y, in: day, pointsPerHour: pointsPerHour)
        return EventInteractionModel.snappedStart(date, in: day, rule: .down, calendar: calendar)
    }
}

private struct TimelineDropDelegate: DropDelegate {
    let interaction: EventInteractionModel
    let autoScroller: TimelineAutoScroller?
    let calendar: Foundation.Calendar
    let date: Date
    let pointsPerHour: CGFloat

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
        autoScroller?.stop()
        interaction.hoverExited()
    }

    func performDrop(info: DropInfo) -> Bool {
        autoScroller?.stop()
        _ = hover(atY: info.location.y)
        interaction.drop(info.itemProviders(for: [.calendarEvent]), calendar: calendar)
        return true
    }

    private func hover(_ info: DropInfo) -> Bool {
        let canDrop = hover(atY: info.location.y)
        if canDrop {
            autoScroller?.update(eventLayerY: info.location.y) { eventLayerY in
                _ = hover(atY: eventLayerY)
            }
        }
        return canDrop
    }

    private func hover(atY y: CGFloat) -> Bool {
        let proposedStart = calendar.date(atY: y, in: date, pointsPerHour: pointsPerHour)
        return interaction.hover(day: date, proposedStart: proposedStart, isTimeline: true, calendar: calendar)
    }
}

private extension Foundation.Calendar {
    /// The time of `day` at `y` in the events layer, where `y = 0` is the start of the day.
    func date(atY y: CGFloat, in day: Date, pointsPerHour: CGFloat) -> Date {
        let elapsedHours = max(y, 0) / max(pointsPerHour, 1)
        return startOfDay(for: day).addingTimeInterval(TimeInterval(elapsedHours) * 3600)
    }
}
