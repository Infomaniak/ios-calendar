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

import AsyncAlgorithms
import CalendarCore
import CalendarCoreUI
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

struct PlanningView: View {
    private static let observeRadiusDays = 7
    private static let observeRecenterThresholdDays = 3

    @Environment(\.calendar) private var calendar
    @Environment(MainViewState.self) private var mainViewState

    @State private var periods: CalendarPeriodCollection?
    @State private var visibleDay: Int?
    @State private var scrollPhase = ScrollPhase.idle
    @State private var anchoredDay: Int?
    @State private var observeCenter: Date?
    @State private var eventsByDay = [Date: [UIEventSummary]]()

    let calendarAccounts: [CalendarAccount.ID: CalendarAccount]

    var body: some View {
        VStack(spacing: 0) {
            if let periods {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        PlanningDaysListView(periods: periods, eventsByDay: eventsByDay, visibleDay: $visibleDay)
                            .scrollsToTopDisabled()
                    }
                    .scrollIndicators(.hidden)
                    .onScrollPhaseChange { previousPhase, phase in
                        scrollPhase = phase
                        if phase == .interacting {
                            anchoredDay = nil
                        }
                        guard previousPhase.isScrolling, phase == .idle else { return }
                        if anchoredDay != nil {
                            restoreAnchoredDay(with: proxy)
                        } else {
                            updateSelectedDate()
                        }
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentSize.height
                    } action: { _, _ in
                        restoreAnchoredDay(with: proxy)
                    }
                    .onAppear {
                        restoreAnchoredDay(with: proxy)
                    }
                    .modifier(PlanningSelectionSyncModifier(
                        visibleDay: $visibleDay,
                        onVisibleDayChange: {
                            guard scrollPhase == .interacting || scrollPhase == .decelerating else { return }
                            updateSelectedDate()
                        },
                        onSelectedDateChange: { date in
                            scroll(to: date, with: proxy)
                            refreshObserveCenterIfNeeded(around: date)
                        }
                    ))
                }
                .id(periods.origin)
            }
        }
        .onChange(of: calendar, initial: true) { _, _ in
            resetPeriods()
        }
        .task(id: observeCenter) {
            guard let observeCenter else { return }
            await observeEvents(
                around: observeCenter,
                range: Self.observeRadiusDays,
                in: calendar
            )
        }
        .id(calendarAccounts)
    }

    private func resetPeriods() {
        let periods = CalendarPeriodCollection(
            calendar: calendar,
            component: .day,
            origin: mainViewState.selectedDate,
            indices: CalendarPeriodOffsets.days
        )
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            self.periods = periods
            scrollPhase = .idle
            anchoredDay = 0
            visibleDay = nil
            observeCenter = periods.origin
            mainViewState.selectedDate = periods.origin
        }
    }

    private func scroll(to date: Date, with proxy: ScrollViewProxy) {
        guard let periods, let index = periods.index(for: date) else {
            resetPeriods()
            return
        }

        let dayDate = periods[index].date
        if date != dayDate {
            mainViewState.selectedDate = dayDate
        }
        guard visibleDay != index, anchoredDay != index else { return }

        anchoredDay = index
        var transaction = Transaction(animation: .default)
        transaction.disablesAnimations = visibleDay.map { abs(index - $0) > 1 } ?? true
        withTransaction(transaction) {
            proxy.scrollTo(index, anchor: .top)
        }
    }

    private func restoreAnchoredDay(with proxy: ScrollViewProxy) {
        guard let anchoredDay, scrollPhase == .idle else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            proxy.scrollTo(anchoredDay, anchor: .top)
        }
    }

    private func updateSelectedDate() {
        guard let index = visibleDay,
              let periods,
              periods.indices.contains(index) else { return }

        let date = periods[index].date
        guard mainViewState.selectedDate != date else { return }
        mainViewState.selectedDate = date
    }

    private func refreshObserveCenterIfNeeded(around date: Date) {
        let day = date.startOfDay(calendar)
        guard let observeCenter,
              let distance = calendar.dateComponents([.day], from: observeCenter, to: day).day else {
            observeCenter = day
            return
        }
        if abs(distance) > Self.observeRecenterThresholdDays {
            self.observeCenter = day
        }
    }

    @concurrent
    private func observeEvents(around center: Date, range: Int, in calendar: Foundation.Calendar) async {
        let startDate = calendar.date(byAdding: .day, value: -range, to: center) ?? center
        let endDate = calendar.date(byAdding: .day, value: range + 1, to: center) ?? center

        @InjectService var calendarSDK: CalendarCoreGraph
        var lastGroupedEvents: [Date: [UIEventSummary]]?
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(
            start: startDate.instant,
            end: endDate.instant
        )._throttle(for: .milliseconds(500)) {
            guard !Task.isCancelled else { return }
            let uiEvents = daySlices.values.flatMap { eventDaySlices in
                eventDaySlices.map {
                    UIEventSummary(eventDaySlice: $0)
                }
            }

            let groupedEvents = Dictionary(grouping: uiEvents) { $0.startDate.startOfDay(calendar) }
                .mapValues { events in
                    events.sorted { lhs, rhs in
                        if lhs.isAllDay != rhs.isAllDay {
                            return lhs.isAllDay
                        }
                        return lhs.startDate < rhs.startDate
                    }
                }
            guard groupedEvents != lastGroupedEvents else { continue }
            lastGroupedEvents = groupedEvents

            guard !Task.isCancelled else { return }
            await MainActor.run {
                eventsByDay = groupedEvents
            }
        }
    }
}

private struct PlanningSelectionSyncModifier: ViewModifier {
    @Environment(\.calendar) private var calendar
    @Environment(MainViewState.self) private var mainViewState

    @Binding var visibleDay: Int?

    let onVisibleDayChange: () -> Void
    let onSelectedDateChange: (Date) -> Void

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(trigger: mainViewState.selectedDate) { oldValue, newValue in
                guard !calendar.isDate(oldValue, inSameDayAs: newValue) else { return nil }
                return .selection
            }
            .onChange(of: visibleDay) { _, _ in
                onVisibleDayChange()
            }
            .onChange(of: mainViewState.selectedDate) { _, date in
                onSelectedDateChange(date)
            }
    }
}

#Preview {
    NavigationStack {
        PlanningView(calendarAccounts: [:])
    }
    .environment(MainViewState())
}
