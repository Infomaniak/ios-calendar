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

struct ScrollInfo: Equatable {
    let offsetX: CGFloat
    let contentWidth: CGFloat
    let containerWidth: CGFloat
}

enum ScrollDirection {
    case past
    case future
}

struct MiniCalendarView: View {
    private static let pageWindow = 3
    private static let moveWindowThreshold = 10

    @State private var weeks: [Date]
    @State private var scrollPosition: ScrollPosition = .init(idType: Date.self)

    @State private var adjustingWindowDirection: ScrollDirection?

    init() {
        _weeks = State(initialValue: Self.generateWeeks(from: Date(), range: -Self.pageWindow ... Self.pageWindow))
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(weeks, id: \.self) { week in
                        MiniCalendarWeekView(weekStartDate: week)
                            .frame(width: proxy.size.width)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition($scrollPosition)
            .defaultScrollAnchor(.center)
            .onScrollGeometryChange(for: ScrollInfo.self) { geometry in
                let offsetX = geometry.contentOffset.x + geometry.contentInsets.leading
                let contentWidth = geometry.contentSize.width
                let containerWidth = geometry.containerSize.width
                return ScrollInfo(offsetX: offsetX, contentWidth: contentWidth, containerWidth: containerWidth)
            } action: { _, newValue in
                guard newValue.contentWidth > 0 else { return }

                let threshold: CGFloat = 100
                let offsetX = newValue.offsetX
                let contentWidth = newValue.contentWidth
                let frameWidth = newValue.containerWidth

                if offsetX > (contentWidth - frameWidth - threshold) && adjustingWindowDirection != .future {
                    adjustWindowFuture()
                }

                if offsetX < threshold && adjustingWindowDirection != .past {
                    adjustWindowPast()
                }
            }
        }
    }

    private static func generateWeeks(from date: Date, range: ClosedRange<Int>) -> [Date] {
        let calendar = Calendar.current
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
            return []
        }

        return range.compactMap { offset in
            calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart)
        }
    }

    private func adjustWindowFuture() {
        guard let lastWeekStart = weeks.last else { return }
        adjustingWindowDirection = .future

        let additionalWeeks = Self.generateWeeks(from: lastWeekStart, range: 1 ... Self.pageWindow)
        weeks.append(contentsOf: additionalWeeks)

        resizeWindowIfNeeded(direction: adjustingWindowDirection)

        Task { @MainActor in
            adjustingWindowDirection = nil
        }
    }

    private func adjustWindowPast() {
        guard let firstWeekStart = weeks.first else { return }
        adjustingWindowDirection = .past

        let additionalWeeks = Self.generateWeeks(from: firstWeekStart, range: -Self.pageWindow ... -1)
        weeks.insert(contentsOf: additionalWeeks, at: 0)

        resizeWindowIfNeeded(direction: adjustingWindowDirection)

        Task { @MainActor in
            adjustingWindowDirection = nil
        }
    }

    private func resizeWindowIfNeeded(direction: ScrollDirection?) {
        guard weeks.count > Self.moveWindowThreshold else { return }

        var transaction = Transaction()
        transaction.scrollPositionUpdatePreservesVelocity = true
        withTransaction(transaction) {
            if direction == .future {
                weeks.removeFirst(Self.pageWindow)
            } else if direction == .past {
                weeks.removeLast(Self.pageWindow)
            }
        }
    }
}

#Preview {
    MiniCalendarView()
}
