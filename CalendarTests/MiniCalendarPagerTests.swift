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
final class MiniCalendarPagerTests: XCTestCase {
    func testMonthNavigationAndLayout() async throws {
        try await checkNavigation(displayMode: .month)
    }

    func testWeekNavigationAndLayout() async throws {
        try await checkNavigation(displayMode: .week)
    }

    func testMonthNavigationInRightToLeftLayout() async throws {
        try await checkNavigation(displayMode: .month, layoutDirection: .rightToLeft)
    }

    func testWeekNavigationWithLargeText() async throws {
        try await checkNavigation(displayMode: .week, dynamicTypeSize: .accessibility3)
    }

    func testWeekNavigationInRightToLeftSafeAreaInset() async throws {
        try await checkNavigation(displayMode: .week, layoutDirection: .rightToLeft, usesSafeAreaInset: true)
    }

    private func checkNavigation(
        displayMode: MiniCalendarView.DisplayMode,
        layoutDirection: LayoutDirection = .leftToRight,
        dynamicTypeSize: DynamicTypeSize = .large,
        usesSafeAreaInset: Bool = false
    ) async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let selectedDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 15)))
        let state = PagerTestState(date: selectedDate, displayMode: displayMode, calendar: calendar)
        let viewModel = MiniCalendarViewModel()
        viewModel.datesWithEventDots[selectedDate] = [.red]
        let controller = UIHostingController(
            rootView: PagerTestView(state: state, usesSafeAreaInset: usesSafeAreaInset)
                .environment(\.layoutDirection, layoutDirection)
                .environment(\.dynamicTypeSize, dynamicTypeSize)
                .environment(viewModel)
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
        var scrollView = try XCTUnwrap(findScrollView(in: controller.view))
        let origin = state.displayedDate
        let component = displayMode.referenceDateInterval
        let initialOffset = scrollView.contentOffset.x
        let initialWidth = scrollView.bounds.width
        XCTAssertEqual(initialWidth, state.width, accuracy: 1)
        XCTAssertEqual(scrollView.bounds.height, DayCellView.maxHeight * (displayMode == .month ? 6 : 1), accuracy: 1)
        XCTAssertGreaterThan(initialOffset, 100 * initialWidth)

        let direction: CGFloat = layoutDirection == .leftToRight ? 1 : -1
        for pageOffset in [1, -1, -24, 24] {
            let targetOffset = initialOffset + CGFloat(pageOffset) * initialWidth * direction
            state.displayedDate = try XCTUnwrap(calendar.date(byAdding: component, value: pageOffset, to: origin))
            try await Task.sleep(for: .seconds(1))
            XCTAssertEqual(scrollView.contentOffset.x, targetOffset, accuracy: 1)
            XCTAssertEqual(state.displayedDate, calendar.date(byAdding: component, value: pageOffset, to: origin))
            XCTAssertEqual(state.selectedDate, selectedDate)
        }

        state.displayedDate = try XCTUnwrap(calendar.date(byAdding: component, value: 120, to: origin))
        try await Task.sleep(for: .seconds(1))
        XCTAssertEqual(scrollView.contentOffset.x, initialOffset + 120 * initialWidth * direction, accuracy: 1)

        state.width = 320
        try await Task.sleep(for: .seconds(1))
        XCTAssertEqual(scrollView.bounds.width, 320, accuracy: 1)
        XCTAssertEqual(scrollView.contentOffset.x.truncatingRemainder(dividingBy: 320), 0, accuracy: 1)
        XCTAssertEqual(state.displayedDate, calendar.date(byAdding: component, value: 120, to: origin))

        let distantDate = try XCTUnwrap(calendar.date(byAdding: .year, value: 150, to: selectedDate))
        state.displayedDate = displayMode.referenceDate(for: distantDate, calendar: calendar)
        try await Task.sleep(for: .seconds(1))
        let resetScrollView = try XCTUnwrap(findScrollView(in: controller.view))
        XCTAssertFalse(resetScrollView === scrollView)
        scrollView = resetScrollView
        XCTAssertEqual(
            scrollView.contentOffset.x,
            (scrollView.contentSize.width - scrollView.bounds.width) / 2,
            accuracy: 1
        )

        state.displayMode = displayMode == .month ? .week : .month
        state.displayedDate = state.displayMode.referenceDate(for: selectedDate, calendar: calendar)
        try await Task.sleep(for: .seconds(1))
        scrollView = try XCTUnwrap(findScrollView(in: controller.view))
        XCTAssertEqual(scrollView.bounds.height, DayCellView.maxHeight * (state.displayMode == .month ? 6 : 1), accuracy: 1)
        XCTAssertEqual(state.displayedDate, state.displayMode.referenceDate(for: selectedDate, calendar: calendar))
        XCTAssertEqual(state.selectedDate, selectedDate)

        let dateBeforeCalendarChange = state.displayedDate
        state.calendar.firstWeekday = 1
        state.calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        try await Task.sleep(for: .seconds(1))
        XCTAssertEqual(
            state.displayedDate,
            state.displayMode.referenceDate(for: dateBeforeCalendarChange, calendar: state.calendar)
        )
        let updatedScrollView = try XCTUnwrap(findScrollView(in: controller.view))
        XCTAssertFalse(updatedScrollView === scrollView)
        XCTAssertEqual(
            updatedScrollView.contentOffset.x,
            (updatedScrollView.contentSize.width - updatedScrollView.bounds.width) / 2,
            accuracy: 1
        )
    }

    @Observable
    fileprivate final class PagerTestState {
        var selectedDate: Date
        var displayedDate: Date
        var displayMode: MiniCalendarView.DisplayMode
        var width: CGFloat = 390
        var calendar: Calendar

        init(date: Date, displayMode: MiniCalendarView.DisplayMode, calendar: Calendar) {
            selectedDate = date
            self.displayMode = displayMode
            self.calendar = calendar
            displayedDate = displayMode.referenceDate(for: date, calendar: calendar)
        }
    }

    private struct PagerTestView: View {
        @Bindable var state: PagerTestState
        let usesSafeAreaInset: Bool

        var body: some View {
            Group {
                if usesSafeAreaInset {
                    ScrollView {
                        Color.clear.frame(height: 1000)
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        VStack(spacing: 0) {
                            DayOfWeekView()
                            pager
                        }
                    }
                } else {
                    pager
                }
            }
            .environment(\.calendar, state.calendar)
        }

        private var pager: some View {
            MiniCalendarPager(
                displayMode: state.displayMode,
                selectedDate: $state.selectedDate,
                displayedDate: $state.displayedDate
            )
            .frame(width: state.width)
        }
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView, scrollView.contentSize.width > scrollView.bounds.width {
            return scrollView
        }
        return view.subviews.lazy.compactMap { self.findScrollView(in: $0) }.first
    }
}
