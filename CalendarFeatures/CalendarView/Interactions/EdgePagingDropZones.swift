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
    /// While an event is moved, holding it near the leading or trailing edge pages `date` by one `component`.
    func edgePagingDropZones(component: Calendar.Component, date: Binding<Date>) -> some View {
        overlay {
            EdgePagingDropZones(component: component, date: date)
        }
    }
}

private struct EdgePagingDropZones: View {
    private static let zoneWidth: CGFloat = 28

    @Environment(\.calendar) private var calendar

    @Environment(EventInteractionModel.self) private var interaction

    @State private var pager = EdgePager()

    let component: Calendar.Component
    @Binding var date: Date

    var body: some View {
        if interaction.isMoving {
            HStack(spacing: 0) {
                zone(direction: -1)
                Spacer(minLength: 0)
                zone(direction: 1)
            }
            .onDisappear {
                pager.stop()
            }
        }
    }

    private func zone(direction: Int) -> some View {
        Color.clear
            .frame(width: Self.zoneWidth)
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .onDrop(of: [.calendarEvent], delegate: EdgePagingDropDelegate(interaction: interaction, pager: pager) {
                page(by: direction)
            })
    }

    private func page(by value: Int) {
        date = calendar.date(byAdding: component, value: value, to: date) ?? date
    }
}

@MainActor
private final class EdgePager {
    private static let pagingDelay = Duration.milliseconds(600)

    private var task: Task<Void, Never>?

    func start(onPage: @escaping () -> Void) {
        stop()
        task = Task {
            while !Task.isCancelled {
                guard await (try? Task.sleep(for: Self.pagingDelay)) != nil else { return }
                onPage()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}

/// Edges only page: dropping there cancels the move.
private struct EdgePagingDropDelegate: DropDelegate {
    let interaction: EventInteractionModel
    let pager: EdgePager
    let onPage: () -> Void

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.calendarEvent])
    }

    func dropEntered(info: DropInfo) {
        guard interaction.keepMoveAlive() else { return }
        pager.start(onPage: onPage)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        _ = interaction.keepMoveAlive()
        return DropProposal(operation: .cancel)
    }

    func dropExited(info: DropInfo) {
        pager.stop()
        interaction.hoverExited()
    }

    func performDrop(info: DropInfo) -> Bool {
        dropExited(info: info)
        return false
    }
}
