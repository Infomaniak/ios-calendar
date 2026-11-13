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
    /// Locations are read in the column's coordinate space, where `y = 0` is the start of the day.
    func timelineInteractions(date: Date, pointsPerHour: CGFloat) -> some View {
        modifier(TimelineInteractionsModifier(date: date, pointsPerHour: pointsPerHour))
    }
}

private struct TimelineInteractionsModifier: ViewModifier {
    @Environment(\.calendar) private var calendar
    @Environment(\.timelineAutoScroller) private var autoScroller
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
                TimelinePlaceholderLayer(date: date, pointsPerHour: pointsPerHour)
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
        let start = creationStart(atY: location.y)

        switch phase {
        case .began:
            interaction.beginCreation(at: start, calendar: calendar)
        case .changed:
            interaction.updateCreation(to: start)
            autoScroller?.update(eventLayerY: location.y) { [interaction] eventLayerY in
                interaction.updateCreation(to: creationStart(atY: eventLayerY))
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

    private func creationStart(atY y: CGFloat) -> Date {
        return TimelineDropDelegate.snappedDate(atY: y, in: date, pointsPerHour: pointsPerHour, calendar: calendar)
    }
}

struct TimelineDropDelegate: DropDelegate {
    let interaction: EventInteractionModel
    let autoScroller: TimelineAutoScroller?
    let calendar: Foundation.Calendar
    let date: Date
    let pointsPerHour: CGFloat

    static func date(atY y: CGFloat, in day: Date, pointsPerHour: CGFloat, calendar: Foundation.Calendar) -> Date {
        let elapsedHours = max(y, 0) / max(pointsPerHour, 1)
        return calendar.startOfDay(for: day).addingTimeInterval(TimeInterval(elapsedHours) * 3600)
    }

    /// Start of the 15 minutes slot under `y`, kept inside the day.
    static func snappedDate(atY y: CGFloat, in day: Date, pointsPerHour: CGFloat, calendar: Foundation.Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let snapInterval = EventInteractionModel.snapInterval
        let elapsed = date(atY: y, in: day, pointsPerHour: pointsPerHour, calendar: calendar).timeIntervalSince(startOfDay)
        let snappedElapsed = (elapsed / snapInterval).rounded(.down) * snapInterval
        let latestStart = startOfNextDay.timeIntervalSince(startOfDay) - snapInterval
        return startOfDay.addingTimeInterval(min(snappedElapsed, latestStart))
    }

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
        let proposedStart = Self.date(atY: y, in: date, pointsPerHour: pointsPerHour, calendar: calendar)
        return interaction.hover(day: date, proposedStart: proposedStart, isTimeline: true, calendar: calendar)
    }
}
