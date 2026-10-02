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

enum CalendarPeriodPagerScrollBehavior {
    /// Scrolls the whole container width at once.
    case paging
    /// Snaps to each period and moves by a single period per gesture when several are visible.
    case viewAligned
}

/// Shares the scroll state of a `CalendarPeriodPager` so a `CalendarPeriodPagerMirror` can follow it.
@Observable
@MainActor
final class CalendarPeriodPagerScrollSync {
    fileprivate(set) var periods: CalendarPeriodCollection?
    fileprivate(set) var generation = 0
    fileprivate(set) var contentOffset = CGFloat.zero
}

struct CalendarPeriodPager<Content: View>: View {
    @Environment(\.calendar) private var calendar

    @State private var periods: CalendarPeriodCollection?
    @State private var visiblePeriod: Int?
    @State private var scrollPhase = ScrollPhase.idle

    let component: Calendar.Component
    let periodOffsets: Range<Int>
    var viewCount = 1
    var scrollBehavior = CalendarPeriodPagerScrollBehavior.paging
    var scrollSync: CalendarPeriodPagerScrollSync?

    @Binding var date: Date

    @ViewBuilder let content: (Date) -> Content

    /// The date bound to the pager is the leading period when several periods are visible.
    private var scrollAnchor: UnitPoint {
        return viewCount > 1 ? .leading : .center
    }

    var body: some View {
        VStack(spacing: 0) {
            if let periods {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(periods) { period in
                            CalendarPeriodPage(period: period, content: content)
                                .containerRelativeFrame(.horizontal, count: viewCount, spacing: 0)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden, axes: .horizontal)
                .calendarPeriodScrollTargetBehavior(scrollBehavior)
                .scrollPosition(id: $visiblePeriod, anchor: scrollAnchor)
                .onScrollGeometryChange(for: CGFloat.self) { scrollGeometry in
                    scrollGeometry.contentOffset.x
                } action: { _, contentOffset in
                    scrollSync?.contentOffset = contentOffset
                }
                .onScrollPhaseChange { previousPhase, phase in
                    NSLog("%@", "DBG[\(viewCount)] phase \(previousPhase) -> \(phase) visible=\(String(describing: visiblePeriod))")
                    scrollPhase = phase
                    guard previousPhase.isScrolling, phase == .idle else { return }
                    updateDate()
                }
                .id(periods.origin)
                .id(component)
                .id(calendar)
            }
        }
        .onChange(of: calendar, initial: true) { _, _ in
            resetPeriods()
        }
        .onChange(of: component) { _, _ in
            resetPeriods()
        }
        .onChange(of: visiblePeriod) { old, new in
            NSLog("%@", "DBG[\(viewCount)] visiblePeriod \(String(describing: old)) -> \(String(describing: new)) phase=\(scrollPhase)")
            guard scrollPhase == .interacting || scrollPhase == .decelerating else { return }
            updateDate()
        }
        .onChange(of: date) { old, date in
            NSLog("%@", "DBG[\(viewCount)] date \(old) -> \(date)")
            if let periods, let index = periods.index(for: date) {
                let periodDate = periods[index].date
                if date != periodDate {
                    self.date = periodDate
                }
                guard visiblePeriod != index else { return }

                var transaction = Transaction(animation: .default)
                transaction.disablesAnimations = visiblePeriod.map { abs(index - $0) > 1 } ?? true
                withTransaction(transaction) {
                    visiblePeriod = index
                }
            } else {
                resetPeriods()
            }
        }
    }

    private func resetPeriods() {
        let periods = CalendarPeriodCollection(
            calendar: calendar,
            component: component,
            origin: date,
            indices: periodOffsets
        )
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            self.periods = periods
            scrollSync?.periods = periods
            scrollSync?.generation += 1
            scrollPhase = .idle
            visiblePeriod = 0
            date = periods.origin
        }
    }

    private func updateDate() {
        guard let index = visiblePeriod,
              let periods,
              periods.indices.contains(index) else { return }

        let date = periods[index].date
        guard self.date != date else { return }
        self.date = date
    }
}

/// Non-interactive copy of a `CalendarPeriodPager` that follows its scroll position, e.g. a header above a timeline.
/// It must have the same width as the followed pager.
struct CalendarPeriodPagerMirror<Content: View>: View {
    let scrollSync: CalendarPeriodPagerScrollSync
    var viewCount = 1

    @ViewBuilder let content: (Date) -> Content

    var body: some View {
        if let periods = scrollSync.periods {
            CalendarPeriodMirrorScrollView(
                periods: periods,
                scrollSync: scrollSync,
                viewCount: viewCount,
                content: content
            )
            .id(scrollSync.generation)
        }
    }
}

private struct CalendarPeriodMirrorScrollView<Content: View>: View {
    @State private var scrollPosition: ScrollPosition

    let periods: CalendarPeriodCollection
    let scrollSync: CalendarPeriodPagerScrollSync
    let viewCount: Int
    let content: (Date) -> Content

    init(
        periods: CalendarPeriodCollection,
        scrollSync: CalendarPeriodPagerScrollSync,
        viewCount: Int,
        content: @escaping (Date) -> Content
    ) {
        _scrollPosition = State(initialValue: ScrollPosition(x: scrollSync.contentOffset))
        self.periods = periods
        self.scrollSync = scrollSync
        self.viewCount = viewCount
        self.content = content
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(periods) { period in
                    CalendarPeriodPage(period: period, content: content)
                        .containerRelativeFrame(.horizontal, count: viewCount, spacing: 0)
                }
            }
        }
        .scrollIndicators(.hidden, axes: .horizontal)
        .scrollDisabled(true)
        .scrollPosition($scrollPosition)
        .onChange(of: scrollSync.contentOffset) { _, contentOffset in
            scrollPosition.scrollTo(x: contentOffset)
        }
    }
}

private extension View {
    @ViewBuilder
    func calendarPeriodScrollTargetBehavior(_ behavior: CalendarPeriodPagerScrollBehavior) -> some View {
        switch behavior {
        case .paging:
            scrollTargetBehavior(.paging)
        case .viewAligned:
            scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        }
    }
}

private struct CalendarPeriodPage<Content: View>: View {
    let period: CalendarPeriodCollection.Period
    @ViewBuilder let content: (Date) -> Content

    var body: some View {
        content(period.date)
    }
}
