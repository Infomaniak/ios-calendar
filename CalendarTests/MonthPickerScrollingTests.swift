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
final class MonthPickerScrollingTests: XCTestCase {
    func testScrollingDoesNotJumpToAnotherDecade() async throws {
        try await checkScrolling()
    }

    func testScrollingWithLargeTextDoesNotJumpToAnotherDecade() async throws {
        try await checkScrolling(dynamicTypeSize: .accessibility3)
    }

    func testScrollingInRightToLeftLayoutDoesNotJumpToAnotherDecade() async throws {
        try await checkScrolling(layoutDirection: .rightToLeft)
    }

    private func checkScrolling(
        dynamicTypeSize: DynamicTypeSize = .large,
        layoutDirection: LayoutDirection = .leftToRight
    ) async throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))
        let state = MonthPickerTestState(date: date)
        let picker = MonthPickerTestView(state: state)
            .environment(\.calendar, calendar)
            .environment(\.dynamicTypeSize, dynamicTypeSize)
            .environment(\.layoutDirection, layoutDirection)
        let controller = UIHostingController(rootView: picker)
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
        let scrollView = try XCTUnwrap(findScrollView(in: controller.view))
        let initialOffset = scrollView.contentOffset.x
        XCTAssertGreaterThan(initialOffset, scrollView.bounds.width)

        for direction in [-1.0, 1.0] {
            for _ in 0 ..< 20 {
                let offset = scrollView.contentOffset.x + direction * 250
                scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
                try await Task.sleep(for: .milliseconds(50))
                // Lazy layout may refine nearby cell widths, but must not jump years away.
                XCTAssertEqual(scrollView.contentOffset.x, offset, accuracy: 250)
            }
        }
        XCTAssertEqual(state.selectedDate, date)
        XCTAssertEqual(state.displayedDate, date)

        state.displayedDate = try XCTUnwrap(calendar.date(byAdding: .month, value: 600, to: date))
        try await Task.sleep(for: .seconds(1))
        if layoutDirection == .leftToRight {
            XCTAssertGreaterThan(scrollView.contentOffset.x, initialOffset + 10000)
        } else {
            XCTAssertLessThan(scrollView.contentOffset.x, initialOffset - 10000)
        }

        state.displayedDate = try XCTUnwrap(calendar.date(byAdding: .month, value: 1800, to: date))
        try await Task.sleep(for: .seconds(1))
        let resetScrollView = try XCTUnwrap(findScrollView(in: controller.view))
        XCTAssertFalse(resetScrollView === scrollView)
        let centeredOffset = (resetScrollView.contentSize.width - resetScrollView.bounds.width) / 2
        XCTAssertEqual(resetScrollView.contentOffset.x, centeredOffset, accuracy: resetScrollView.contentSize.width * 0.1)
    }

    @MainActor
    @Observable
    fileprivate final class MonthPickerTestState {
        var selectedDate: Date
        var displayedDate: Date

        init(date: Date) {
            selectedDate = date
            displayedDate = date
        }
    }

    private struct MonthPickerTestView: View {
        @Bindable var state: MonthPickerTestState

        var body: some View {
            MonthPickerView(selectedDate: $state.selectedDate, displayedDate: $state.displayedDate)
        }
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        return view.subviews.lazy.compactMap { self.findScrollView(in: $0) }.first
    }
}
