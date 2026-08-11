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

    static func fromScrollInfo(_ scrollInfo: ScrollInfo) -> ScrollDirection? {
        if scrollInfo.offsetX < 0 {
            return .past
        } else if scrollInfo.offsetX > (scrollInfo.containerWidth * 2) {
            return .future
        } else {
            return nil
        }
    }
}

struct InfiniteScrollView<ContentView: View>: View {
    @Environment(\.calendar) private var calendar

    @State private var referenceDates = [Date]()
    @State private var scrollPosition: ScrollPosition = .init()

    @State private var isLocked = false
    @State private var lockedId: Date?

    let referenceDateInterval: Calendar.Component

    @Binding var selectedDate: Date
    @Binding var displayedDate: Date

    @ViewBuilder var content: (Date) -> ContentView

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(referenceDates, id: \.self) { referenceDate in
                    content(referenceDate)
                        .containerRelativeFrame(.horizontal)
                        .visualEffect { [isLocked, lockedId] content, proxy in
                            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
                            let opacity: Double = !isLocked || lockedId == referenceDate ? 1 : 0

                            return content
                                .opacity(opacity)
                                .offset(x: isLocked ? -minX : 0)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition($scrollPosition)
        .defaultScrollAnchor(.center, for: .initialOffset)
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
                range: -1 ... 1
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

        withAnimation {
            if !referenceDates.contains(where: { $0 == selectedDateReferenceStart }) {
                referenceDates = generateReferenceDates(
                    from: selectedDateReferenceStart,
                    range: -1 ... 1
                )
            }

            scrollPosition.scrollTo(id: selectedDateReferenceStart)
        }
    }

    private func adjustWindowIfNeeded(_ scrollInfo: ScrollInfo) {
        guard scrollInfo.contentWidth > 0 else { return }

        let scrollDirection = ScrollDirection.fromScrollInfo(scrollInfo)
        if let scrollDirection, !isLocked {
            isLocked = true
            if scrollDirection == .past {
                lockedId = referenceDates.first
                referenceDates.insert(contentsOf: generateReferenceDates(from: referenceDates.first!, range: -2 ... -1), at: 0)
                referenceDates.removeLast(2)
            } else {
                lockedId = referenceDates.last
                referenceDates.append(contentsOf: generateReferenceDates(from: referenceDates.last!, range: 1 ... 2))
                referenceDates.removeFirst(2)
            }
        } else if isLocked {
            var transaction = Transaction()
            transaction.scrollPositionUpdatePreservesVelocity = true
            withTransaction(transaction) {
                if scrollDirection == .future {
                    scrollPosition.scrollTo(x: -scrollInfo.containerWidth * 2)
                } else if scrollDirection == .past {
                    scrollPosition.scrollTo(x: scrollInfo.containerWidth * 2)
                }
            }

            DispatchQueue.main.async {
                lockedId = nil
                isLocked = false
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
