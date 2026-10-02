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

@testable import CalendarCalendarView
import SwiftUI
import XCTest

@MainActor
final class MultipleDaysPagerTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    func testWeekLayoutDates() throws {
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 14)))
        let layout = MultipleDaysLayout.week

        let pagerDate = layout.pagerDate(for: date, calendar: calendar)
        XCTAssertEqual(pagerDate, calendar.date(from: DateComponents(year: 2026, month: 9, day: 28)))

        let dates = layout.pageDates(for: pagerDate, calendar: calendar)
        XCTAssertEqual(dates.count, 7)
        XCTAssertEqual(dates.first, pagerDate)
        XCTAssertEqual(dates.last, calendar.date(from: DateComponents(year: 2026, month: 10, day: 4)))

        let preloadedInterval = try XCTUnwrap(layout.preloadedInterval(for: date, calendar: calendar))
        XCTAssertEqual(preloadedInterval.start, calendar.date(from: DateComponents(year: 2026, month: 9, day: 21)))
        XCTAssertEqual(preloadedInterval.end, calendar.date(from: DateComponents(year: 2026, month: 10, day: 12)))
    }

    func testThreeDaysLayoutDates() throws {
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 14)))
        let layout = MultipleDaysLayout.threeDays

        let pagerDate = layout.pagerDate(for: date, calendar: calendar)
        XCTAssertEqual(pagerDate, calendar.startOfDay(for: date))
        XCTAssertEqual(layout.pageDates(for: pagerDate, calendar: calendar), [pagerDate])
        XCTAssertEqual(layout.pagerViewCount, 3)

        let visibleInterval = try XCTUnwrap(layout.visibleInterval(for: date, calendar: calendar))
        XCTAssertEqual(visibleInterval.start, pagerDate)
        XCTAssertEqual(visibleInterval.end, calendar.date(from: DateComponents(year: 2026, month: 10, day: 4)))

        let preloadedInterval = try XCTUnwrap(layout.preloadedInterval(for: date, calendar: calendar))
        XCTAssertEqual(preloadedInterval.start, calendar.date(from: DateComponents(year: 2026, month: 9, day: 28)))
        XCTAssertEqual(preloadedInterval.end, calendar.date(from: DateComponents(year: 2026, month: 10, day: 7)))
    }

    func testDayByDayNavigationKeepsSelectedDayLeading() async throws {
        try await checkDayByDayNavigation(layoutDirection: .leftToRight)
    }

    func testDayByDayNavigationKeepsSelectedDayLeadingInRightToLeft() async throws {
        try await checkDayByDayNavigation(layoutDirection: .rightToLeft)
    }

    private func checkDayByDayNavigation(layoutDirection: LayoutDirection) async throws {
        let calendar = calendar
        let origin = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let state = PagerTestState(date: origin)
        let width: CGFloat = 390
        let columnWidth = width / 3
        let controller = UIHostingController(
            rootView: PagerTestView(state: state, width: width)
                .environment(\.calendar, calendar)
                .environment(\.layoutDirection, layoutDirection)
        )
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previousWindow = scene.keyWindow
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousWindow?.makeKeyAndVisible()
        }
        try await Task.sleep(for: .seconds(1))

        let scrollViews = findScrollViews(in: controller.view)
        XCTAssertEqual(scrollViews.count, 2)
        let pager = try XCTUnwrap(scrollViews.first { $0.isScrollEnabled })
        let mirror = try XCTUnwrap(scrollViews.first { !$0.isScrollEnabled })

        let leadingOffset = MultipleDaysLayout.threeDays.pagerOffsets.lowerBound
        let originOffset = CGFloat(-leadingOffset) * columnWidth
        let expectedInitialOffset = layoutDirection == .leftToRight
            ? originOffset
            : pager.contentSize.width - pager.bounds.width - originOffset
        XCTAssertEqual(pager.contentOffset.x, expectedInitialOffset, accuracy: 1)
        XCTAssertEqual(mirror.contentOffset.x, pager.contentOffset.x, accuracy: 1)

        let direction: CGFloat = layoutDirection == .leftToRight ? 1 : -1
        for dayOffset in [1, 2, -1, -30, 30] {
            state.selectedDate = try XCTUnwrap(calendar.date(byAdding: .day, value: dayOffset, to: origin))
            try await Task.sleep(for: .seconds(1))
            XCTAssertEqual(
                pager.contentOffset.x,
                expectedInitialOffset + CGFloat(dayOffset) * columnWidth * direction,
                accuracy: 1
            )
            XCTAssertEqual(mirror.contentOffset.x, pager.contentOffset.x, accuracy: 1)
        }
    }

    @Observable
    fileprivate final class PagerTestState {
        var selectedDate: Date

        init(date: Date) {
            selectedDate = date
        }
    }

    private struct PagerTestView: View {
        @State private var scrollSync = CalendarPeriodPagerScrollSync()

        @Bindable var state: PagerTestState
        let width: CGFloat

        var body: some View {
            let layout = MultipleDaysLayout.threeDays
            VStack(spacing: 0) {
                CalendarPeriodPagerMirror(scrollSync: scrollSync, viewCount: layout.pagerViewCount) { date in
                    Text(date, format: .dateTime.day())
                }
                .fixedSize(horizontal: false, vertical: true)

                CalendarPeriodPager(
                    component: layout.pagerComponent,
                    periodOffsets: layout.pagerOffsets,
                    viewCount: layout.pagerViewCount,
                    scrollBehavior: layout.pagerScrollBehavior,
                    scrollSync: scrollSync,
                    date: $state.selectedDate
                ) { date in
                    Text(date, format: .dateTime.day())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: 200)
            }
            .frame(width: width)
        }
    }

    private func findScrollViews(in view: UIView) -> [UIScrollView] {
        var scrollViews = [UIScrollView]()
        if let scrollView = view as? UIScrollView, scrollView.contentSize.width > scrollView.bounds.width {
            scrollViews.append(scrollView)
        }
        return scrollViews + view.subviews.flatMap { findScrollViews(in: $0) }
    }
}
