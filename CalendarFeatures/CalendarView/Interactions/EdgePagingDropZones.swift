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
    /// While an event is moved, holding it near the leading or trailing edge pages to the previous or next period.
    ///
    /// - Parameter onPage: Called with `-1` or `1` on every paging step.
    func edgePagingDropZones(onPage: @escaping (Int) -> Void) -> some View {
        overlay {
            EdgePagingOverlay(onPage: onPage)
        }
    }
}

private struct EdgePagingOverlay: View {
    @Environment(EventInteractionModel.self) private var interaction

    let onPage: (Int) -> Void

    var body: some View {
        if interaction.isMoving {
            EdgePagingDropZones(onPage: onPage)
        }
    }
}

private struct EdgePagingDropZones: View {
    private static let zoneWidth: CGFloat = 28

    @Environment(EventInteractionModel.self) private var interaction

    @State private var pager = EdgePager()

    let onPage: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            zone(direction: -1)
            Spacer(minLength: 0)
            zone(direction: 1)
        }
        .onAppear {
            pager.onPage = onPage
        }
        .onDisappear {
            pager.stop()
        }
    }

    private func zone(direction: Int) -> some View {
        Color.clear
            .frame(width: Self.zoneWidth)
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .onDrop(
                of: [.calendarEvent],
                delegate: EdgePagingDropDelegate(interaction: interaction, pager: pager, direction: direction)
            )
    }
}

@MainActor
private final class EdgePager {
    private static let pagingDelay = Duration.milliseconds(600)

    var onPage: ((Int) -> Void)?

    private var task: Task<Void, Never>?

    func start(direction: Int) {
        stop()
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard await (try? Task.sleep(for: Self.pagingDelay)) != nil else { return }
                self?.onPage?(direction)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}

private struct EdgePagingDropDelegate: DropDelegate {
    let interaction: EventInteractionModel
    let pager: EdgePager
    let direction: Int

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.calendarEvent])
    }

    func dropEntered(info: DropInfo) {
        guard interaction.keepMoveAlive() else { return }
        pager.start(direction: direction)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: interaction.keepMoveAlive() ? .move : .forbidden)
    }

    func dropExited(info: DropInfo) {
        pager.stop()
        interaction.hoverExited()
    }

    func performDrop(info: DropInfo) -> Bool {
        pager.stop()
        interaction.hoverExited()
        return false
    }
}
