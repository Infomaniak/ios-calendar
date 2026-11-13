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

import SwiftUI

extension EnvironmentValues {
    @Entry var timelineAutoScroller: TimelineAutoScroller?
}

/// Scrolls the timeline while a drag or a creation gesture stays close to its top or bottom edge.
///
/// Not observable on purpose: it is updated on every scroll frame and must not invalidate views.
@MainActor
final class TimelineAutoScroller {
    private static let edgeInset: CGFloat = 56
    private static let maximumSpeed: CGFloat = 700
    private static let frameInterval: TimeInterval = 1 / 60

    var scrollOffset = CGFloat.zero
    var visibleHeight = CGFloat.zero
    var contentHeight = CGFloat.zero
    /// Position of the events layer (`y = 0` at the start of the day) in the scroll content.
    var eventLayerTop = CGFloat.zero
    var scrollTo: ((CGFloat) -> Void)?

    private var speed = CGFloat.zero
    private var task: Task<Void, Never>?
    private var trackedEventLayerY = CGFloat.zero
    private var onScroll: ((CGFloat) -> Void)?

    /// - Parameters:
    ///   - eventLayerY: Location of the finger in the events layer.
    ///   - onScroll: Called with the location now under the motionless finger after each auto-scroll step.
    func update(eventLayerY: CGFloat, onScroll: @escaping (CGFloat) -> Void) {
        guard visibleHeight > 0 else { return }

        trackedEventLayerY = eventLayerY
        self.onScroll = onScroll

        let visibleY = eventLayerY + eventLayerTop - scrollOffset
        if visibleY < Self.edgeInset {
            speed = -Self.maximumSpeed * min(1, (Self.edgeInset - visibleY) / Self.edgeInset)
        } else if visibleY > visibleHeight - Self.edgeInset {
            speed = Self.maximumSpeed * min(1, (visibleY - visibleHeight + Self.edgeInset) / Self.edgeInset)
        } else {
            speed = 0
        }

        if speed == 0 {
            stop()
        } else {
            startIfNeeded()
        }
    }

    func stop() {
        speed = 0
        onScroll = nil
        task?.cancel()
        task = nil
    }

    private func startIfNeeded() {
        guard task == nil else { return }

        task = Task { [weak self] in
            while !Task.isCancelled {
                guard await (try? Task.sleep(for: .seconds(Self.frameInterval))) != nil, let self else { return }
                let maximumOffset = max(contentHeight - visibleHeight, 0)
                let delta = speed * Self.frameInterval
                let nextOffset = min(max(scrollOffset + delta, 0), maximumOffset)
                guard nextOffset != scrollOffset else { continue }

                trackedEventLayerY += nextOffset - scrollOffset
                scrollOffset = nextOffset
                scrollTo?(nextOffset)
                onScroll?(trackedEventLayerY)
            }
        }
    }
}
