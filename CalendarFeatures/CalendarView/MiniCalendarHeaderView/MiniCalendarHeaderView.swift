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
import UIKit

public struct MiniCalendarHeaderView: UIViewRepresentable {
    @Binding var displayedRange: DateInterval

    public init(displayedRange: Binding<DateInterval>) {
        _displayedRange = displayedRange
    }

    public func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: MiniCalendarHeaderView.makeLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        context.coordinator.collectionView = collectionView

        Task { @MainActor in
            context.coordinator.centerInitially(in: collectionView)
        }

        return collectionView
    }

    public func updateUIView(_ collectionView: UICollectionView, context: Context) {
        let coordinator = context.coordinator
        coordinator.displayedRange = $displayedRange

        guard collectionView.bounds.width > 0 else { return }

        if !coordinator.hasCenteredInitially {
            coordinator.centerInitially(in: collectionView)
        } else {
            coordinator.syncWithExternalRange(displayedRange, in: collectionView)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(displayedRange: $displayedRange)
    }

    private static func makeLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / 7.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            ),
            repeatingSubitem: item,
            count: 7
        )
        group.interItemSpacing = .fixed(0)

        let section = NSCollectionLayoutSection(group: group)

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        return UICollectionViewCompositionalLayout(section: section, configuration: configuration)
    }

    @MainActor
    public final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        private static let windowRadius = 2

        var displayedRange: Binding<DateInterval>
        weak var collectionView: UICollectionView?
        private(set) var hasCenteredInitially = false

        private let calendar = Calendar.current
        private var currentWeekStart: Date
        private var days: [Date] = []
        private var isRecentering = false

        private let cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Date>

        init(displayedRange: Binding<DateInterval>) {
            self.displayedRange = displayedRange
            let calendar = Calendar.current
            currentWeekStart = calendar.startOfWeek(for: displayedRange.wrappedValue.start)

            cellRegistration = .init { cell, _, date in
                cell.contentConfiguration = UIHostingConfiguration {
                    MiniCalendarDayCellView(date: date)
                }
                .margins(.all, 0)
                .background(.clear)
            }

            super.init()
            rebuildWindow()
        }

        // MARK: - Window

        private func rebuildWindow() {
            days = (-Self.windowRadius ... Self.windowRadius).flatMap { weekOffset -> [Date] in
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart) else {
                    return []
                }
                return (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
            }
        }

        private var centerOffsetX: CGFloat {
            guard let width = collectionView?.bounds.width else { return 0 }
            return CGFloat(Self.windowRadius) * width
        }

        func centerInitially(in collectionView: UICollectionView) {
            hasCenteredInitially = true
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            collectionView.setContentOffset(CGPoint(x: centerOffsetX, y: 0), animated: false)
            updateDisplayedWeek()
        }

        func syncWithExternalRange(_ range: DateInterval, in collectionView: UICollectionView) {
            let targetWeekStart = calendar.startOfWeek(for: range.start)
            guard targetWeekStart != currentWeekStart else { return }

            currentWeekStart = targetWeekStart
            rebuildWindow()
            recenter(collectionView)
        }

        private func recenter(_ collectionView: UICollectionView) {
            isRecentering = true
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            collectionView.setContentOffset(CGPoint(x: centerOffsetX, y: 0), animated: false)
            isRecentering = false
        }

        private func updateDisplayedWeek() {
            guard let range = calendar.dateInterval(of: .weekOfYear, for: currentWeekStart) else { return }
            Task { @MainActor in
                if displayedRange.wrappedValue != range {
                    displayedRange.wrappedValue = range
                }
            }
        }

        // MARK: - Paging

        private func handlePagingSettled(_ collectionView: UICollectionView) {
            guard !isRecentering, collectionView.bounds.width > 0 else { return }

            let width = collectionView.bounds.width
            let page = Int((collectionView.contentOffset.x / width).rounded())
            let delta = page - Self.windowRadius

            if delta != 0 {
                currentWeekStart = calendar.date(
                    byAdding: .weekOfYear,
                    value: delta,
                    to: currentWeekStart
                ) ?? currentWeekStart
                rebuildWindow()
                recenter(collectionView)
            }
            updateDisplayedWeek()
        }

        public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            guard let collectionView = scrollView as? UICollectionView else { return }
            handlePagingSettled(collectionView)
        }

        public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            guard let collectionView = scrollView as? UICollectionView else { return }
            handlePagingSettled(collectionView)
        }

        // MARK: - Data source

        public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            days.count
        }

        public func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            let date = days[indexPath.item]
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: date
            )
        }
    }
}

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(for: date)
    }
}

#Preview {
    @Previewable @State var displayedRange = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        ?? DateInterval(start: Date(), duration: 7 * 24 * 60 * 60)

    VStack(spacing: 16) {
        MiniCalendarHeaderView(displayedRange: $displayedRange)
            .frame(height: 64)

        Text(displayedRange.start, format: .dateTime.day().month().year())
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
