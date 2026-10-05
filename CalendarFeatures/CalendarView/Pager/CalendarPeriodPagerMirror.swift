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
