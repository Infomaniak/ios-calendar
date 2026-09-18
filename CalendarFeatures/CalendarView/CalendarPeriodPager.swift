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

struct CalendarPeriodPager<Content: View>: View {
    @Environment(\.calendar) private var calendar

    @State private var periods: CalendarPeriodCollection?
    @State private var visiblePeriod: Int?
    @State private var scrollPhase = ScrollPhase.idle

    let component: Calendar.Component
    let periodOffsets: Range<Int>

    @Binding var date: Date

    @ViewBuilder let content: (Date) -> Content

    var body: some View {
        VStack(spacing: 0) {
            if let periods {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(periods) { period in
                            CalendarPeriodPage(period: period, content: content)
                                .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden, axes: .horizontal)
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $visiblePeriod, anchor: .center)
                .onScrollPhaseChange { previousPhase, phase in
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
        .onChange(of: visiblePeriod) { _, _ in
            guard scrollPhase == .interacting || scrollPhase == .decelerating else { return }
            updateDate()
        }
        .onChange(of: date) { _, date in
            if let periods, let index = periods.index(for: date) {
                let periodDate = periods[index].date
                if date != periodDate {
                    self.date = periodDate
                }
                guard visiblePeriod != index else { return }
                withAnimation {
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

private struct CalendarPeriodPage<Content: View>: View {
    let period: CalendarPeriodCollection.Period
    @ViewBuilder let content: (Date) -> Content

    var body: some View {
        content(period.date)
    }
}
