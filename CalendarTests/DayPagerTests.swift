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
import CalendarCoreUI
import SwiftUI
import XCTest

@MainActor
final class DayPagerTests: XCTestCase {
    func testDayNavigationAndVerticalScrolling() async throws {
        try await checkNavigation()
    }

    func testDayNavigationInRightToLeftLayout() async throws {
        try await checkNavigation(layoutDirection: .rightToLeft)
    }

    private func checkNavigation(layoutDirection: LayoutDirection = .leftToRight) async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Zurich"))
        let initialDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 12)))
        let origin = calendar.startOfDay(for: initialDate)
        let state = DayPagerTestState(date: initialDate, calendar: calendar)
        let controller = UIHostingController(
            rootView: DayPagerTestView(state: state)
                .environment(\.layoutDirection, layoutDirection)
                .environment(DaysViewModel())
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
        let scrollView = try XCTUnwrap(horizontalScrollView(in: controller.view))
        let initialOffset = scrollView.contentOffset.x
        XCTAssertEqual(state.mainViewState.selectedDate, origin)
        XCTAssertEqual(scrollView.bounds.width, state.width, accuracy: 1)
        XCTAssertEqual(scrollView.bounds.height, 600, accuracy: 1)
        XCTAssertEqual(initialOffset, 36525 * state.width, accuracy: 1)
        XCTAssertLessThan(scrollViews(in: scrollView).count, 10)

        let center = CGPoint(x: controller.view.bounds.midX, y: controller.view.bounds.midY)
        let verticalScrollView = try XCTUnwrap(scrollViews(in: scrollView).first {
            $0.contentSize.height > $0.bounds.height &&
                $0.convert($0.bounds, to: controller.view).contains(center)
        })
        let verticalOffset = verticalScrollView.contentOffset.y + 150
        XCTAssertTrue(verticalScrollView.showsVerticalScrollIndicator)
        verticalScrollView.setContentOffset(CGPoint(x: 0, y: verticalOffset), animated: false)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(verticalScrollView.contentOffset.y, verticalOffset, accuracy: 1)
        XCTAssertEqual(scrollView.contentOffset.x, initialOffset, accuracy: 1)
        XCTAssertEqual(state.mainViewState.selectedDate, origin)

        let direction: CGFloat = layoutDirection == .leftToRight ? 1 : -1
        for dayOffset in [-1, 1, 2, -40, 600, 20000] {
            let date = try XCTUnwrap(calendar.date(byAdding: .day, value: dayOffset, to: origin))
            state.mainViewState.selectedDate = date
            try await Task.sleep(for: .seconds(1))
            XCTAssertEqual(state.mainViewState.selectedDate, date)
            XCTAssertEqual(scrollView.contentOffset.x, initialOffset + CGFloat(dayOffset) * state.width * direction, accuracy: 1)
        }

        let selectedDay = state.mainViewState.selectedDate
        let selectedOffset = scrollView.contentOffset.x
        state.mainViewState.selectedDate = try XCTUnwrap(calendar.date(byAdding: .hour, value: 12, to: selectedDay))
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(state.mainViewState.selectedDate, selectedDay)
        XCTAssertEqual(scrollView.contentOffset.x, selectedOffset, accuracy: 1)

        state.width = 320
        try await Task.sleep(for: .seconds(1))
        XCTAssertEqual(scrollView.bounds.width, state.width, accuracy: 1)
        XCTAssertEqual(scrollView.contentOffset.x, (36525 + 20000 * direction) * state.width, accuracy: 1)
        XCTAssertEqual(state.mainViewState.selectedDate, selectedDay)

        let distantDate = try XCTUnwrap(calendar.date(byAdding: .year, value: 150, to: origin))
        state.mainViewState.selectedDate = distantDate
        try await Task.sleep(for: .seconds(1))
        let resetScrollView = try XCTUnwrap(horizontalScrollView(in: controller.view))
        XCTAssertFalse(resetScrollView === scrollView)
        XCTAssertEqual(resetScrollView.contentOffset.x, 36525 * state.width, accuracy: 1)
        XCTAssertEqual(state.mainViewState.selectedDate, calendar.startOfDay(for: distantDate))

        state.calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        try await Task.sleep(for: .seconds(1))
        XCTAssertEqual(state.mainViewState.selectedDate, state.calendar.startOfDay(for: distantDate))
        let updatedScrollView = try XCTUnwrap(horizontalScrollView(in: controller.view))
        XCTAssertFalse(updatedScrollView === resetScrollView)
        XCTAssertEqual(updatedScrollView.contentOffset.x, 36525 * state.width, accuracy: 1)
    }

    @MainActor
    @Observable
    fileprivate final class DayPagerTestState {
        let mainViewState: MainViewState
        var calendar: Calendar
        var width: CGFloat = 390

        init(date: Date, calendar: Calendar) {
            mainViewState = MainViewState(selectedDate: date)
            self.calendar = calendar
        }
    }

    private struct DayPagerTestView: View {
        @Bindable var state: DayPagerTestState

        var body: some View {
            @Bindable var mainViewState = state.mainViewState

            DayPager(selectedDate: $mainViewState.selectedDate, miniCalendarHeight: .constant(0))
                .frame(width: state.width, height: 600)
                .environment(\.calendar, state.calendar)
                .environment(mainViewState)
        }
    }

    private func horizontalScrollView(in view: UIView) -> UIScrollView? {
        scrollViews(in: view).first { $0.contentSize.width > $0.bounds.width }
    }

    private func scrollViews(in view: UIView) -> [UIScrollView] {
        let scrollView = (view as? UIScrollView).map { [$0] } ?? []
        return scrollView + view.subviews.flatMap { scrollViews(in: $0) }
    }
}
