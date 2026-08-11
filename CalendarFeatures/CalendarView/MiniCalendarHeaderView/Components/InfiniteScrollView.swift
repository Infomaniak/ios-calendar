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

import DesignSystem
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

enum InfiniteScrollConstants {
    static let pageWindow = 3
    static let moveWindowThreshold = 10
    static let adjustWindowThreshold: CGFloat = 100
}

struct InfiniteScrollView<ContentView: View>: View {
    @Environment(\.calendar) private var calendar

    @State private var referenceDates = [Date]()
    @State private var scrollPosition: ScrollPosition = .init(idType: Date.self)

    @State private var adjustingWindowDirection: ScrollDirection?
    @State private var isProgrammaticallyScrolling = false

    let referenceDateInterval: Calendar.Component

    @Binding var selectedDate: Date
    @Binding var displayedDate: Date

    @ViewBuilder var content: (Date) -> ContentView

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(referenceDates, id: \.self) { referenceDate in
                    content(referenceDate)
                        .containerRelativeFrame(.horizontal)
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
            adjustWindowIfNeeded(newValue)
        }
        .onScrollPhaseChange { _, newPhase, context in
            if newPhase == .decelerating || newPhase == .idle {
                let offsetX = context.geometry.contentOffset.x + context.geometry.contentInsets.leading
                let contentWidth = context.geometry.contentSize.width
                let containerWidth = context.geometry.containerSize.width
                let scrollInfo = ScrollInfo(offsetX: offsetX, contentWidth: contentWidth, containerWidth: containerWidth)
                updateDisplayedDate(scrollInfo)
            }
        }
        .onAppear {
            referenceDates = generateReferenceDates(
                from: displayedDate,
                range: -InfiniteScrollConstants.pageWindow ... InfiniteScrollConstants.pageWindow
            )
        }
        .onChange(of: selectedDate) { _, newValue in
            scrollToSelectedDateIfNeeded(newValue)
        }
    }

    private func updateDisplayedDate(_ scrollInfo: ScrollInfo) {
        guard scrollInfo.containerWidth > 0, !referenceDates.isEmpty else { return }

        let pageIndex = Int((scrollInfo.offsetX / scrollInfo.containerWidth).rounded())
        guard referenceDates.indices.contains(pageIndex) else { return }

        let visibleDate = referenceDates[pageIndex]
        guard displayedDate != visibleDate else { return }
        displayedDate = visibleDate
    }

    private func generateReferenceDates(from date: Date, range: ClosedRange<Int>) -> [Date] {
        guard let currentReferenceStart = calendar.dateInterval(of: referenceDateInterval, for: date)?.start else {
            return []
        }

        return range.compactMap { offset in
            calendar.date(byAdding: referenceDateInterval, value: offset, to: currentReferenceStart)
        }
    }

    private func scrollToSelectedDateIfNeeded(_ date: Date) {
        guard let selectedDateReferenceStart = calendar.dateInterval(of: referenceDateInterval, for: date)?.start,
              selectedDateReferenceStart != scrollPosition.viewID as? Date else {
            return
        }

        isProgrammaticallyScrolling = true
        withAnimation {
            if !referenceDates.contains(where: { $0 == selectedDateReferenceStart }) {
                referenceDates = generateReferenceDates(
                    from: selectedDateReferenceStart,
                    range: -InfiniteScrollConstants.pageWindow ... InfiniteScrollConstants.pageWindow
                )
            }

            scrollPosition.scrollTo(id: selectedDateReferenceStart)
        }
        isProgrammaticallyScrolling = false
    }

    private func adjustWindowIfNeeded(_ scrollInfo: ScrollInfo) {
        guard scrollInfo.contentWidth > 0, !isProgrammaticallyScrolling else { return }

        let offsetX = scrollInfo.offsetX
        let contentWidth = scrollInfo.contentWidth
        let containerWidth = scrollInfo.containerWidth

        if offsetX > (contentWidth - containerWidth - InfiniteScrollConstants.adjustWindowThreshold)
            && adjustingWindowDirection != .future {
            adjustWindowFuture()
        } else if offsetX < InfiniteScrollConstants.adjustWindowThreshold && adjustingWindowDirection != .past {
            adjustWindowPast()
        }
    }

    private func adjustWindowFuture() {
        guard let lastReferenceStart = referenceDates.last else { return }
        adjustingWindowDirection = .future

        let additionalWeeks = generateReferenceDates(from: lastReferenceStart, range: 1 ... InfiniteScrollConstants.pageWindow)
        referenceDates.append(contentsOf: additionalWeeks)

        resizeWindowIfNeeded(direction: adjustingWindowDirection)

        Task { @MainActor in
            adjustingWindowDirection = nil
        }
    }

    private func adjustWindowPast() {
        guard let firstReferenceStart = referenceDates.first else { return }
        adjustingWindowDirection = .past

        let additionalWeeks = generateReferenceDates(from: firstReferenceStart, range: -InfiniteScrollConstants.pageWindow ... -1)
        referenceDates.insert(contentsOf: additionalWeeks, at: 0)

        resizeWindowIfNeeded(direction: adjustingWindowDirection)

        Task { @MainActor in
            adjustingWindowDirection = nil
        }
    }

    private func resizeWindowIfNeeded(direction: ScrollDirection?) {
        guard referenceDates.count > InfiniteScrollConstants.moveWindowThreshold else { return }

        var transaction = Transaction()
        transaction.scrollPositionUpdatePreservesVelocity = true
        withTransaction(transaction) {
            if direction == .future {
                referenceDates.removeFirst(InfiniteScrollConstants.pageWindow)
            } else if direction == .past {
                referenceDates.removeLast(InfiniteScrollConstants.pageWindow)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    @Previewable @State var displayedDate = Date()
    InfiniteScrollView(
        referenceDateInterval: .weekOfYear,
        selectedDate: $selectedDate,
        displayedDate: $displayedDate
    ) { date in
        WeekHeaderView(startDate: date, selectedDate: $selectedDate)
    }
}
