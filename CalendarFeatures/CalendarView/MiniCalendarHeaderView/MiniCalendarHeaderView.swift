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
    @Binding var selectedDate: Date

    public init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
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
        coordinator.selectedDate = $selectedDate

        guard collectionView.bounds.width > 0 else { return }

        if !coordinator.hasCenteredInitially {
            coordinator.centerInitially(in: collectionView)
        } else {
            coordinator.syncWithExternalDate(selectedDate, in: collectionView)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(selectedDate: $selectedDate)
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
        private static let windowRadius = 10

        var selectedDate: Binding<Date>
        weak var collectionView: UICollectionView?
        private(set) var hasCenteredInitially = false

        private let calendar = Calendar.current
        private var renderedWeekStart: Date
        private var renderedSelectedDate: Date

        private var days: [Date] = []
        private var isRecentering = false

        private let cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Date>

        init(selectedDate: Binding<Date>) {
            self.selectedDate = selectedDate
            let calendar = Calendar.current
            renderedWeekStart = calendar.startOfWeek(for: selectedDate.wrappedValue)
            renderedSelectedDate = selectedDate.wrappedValue
            cellRegistration = .init { cell, _, date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate.wrappedValue)
                cell.contentConfiguration = UIHostingConfiguration {
                    MiniCalendarDayCellView(date: date, isSelected: isSelected)
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
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: renderedWeekStart) else {
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
        }

        func syncWithExternalDate(_ date: Date, in collectionView: UICollectionView) {
            let targetWeekStart = calendar.startOfWeek(for: date)
            guard targetWeekStart != renderedWeekStart else {
                if !calendar.isDate(date, inSameDayAs: renderedSelectedDate) {
                    renderedSelectedDate = date
                    collectionView.reloadData()
                }
                return
            }

            renderedSelectedDate = date
            renderedWeekStart = targetWeekStart
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

        // MARK: - Paging

        private func handlePagingSettled(_ collectionView: UICollectionView) {
            guard !isRecentering, collectionView.bounds.width > 0 else { return }

            let width = collectionView.bounds.width
            let page = Int((collectionView.contentOffset.x / width).rounded())
            let delta = page - Self.windowRadius
            guard delta != 0 else { return }

            let newWeekStart = calendar.date(
                byAdding: .weekOfYear,
                value: delta,
                to: renderedWeekStart
            ) ?? renderedWeekStart

            let weekStartOfSelected = calendar.startOfWeek(for: selectedDate.wrappedValue)
            let dayOffset = calendar.dateComponents(
                [.day],
                from: weekStartOfSelected,
                to: selectedDate.wrappedValue
            ).day ?? 0
            let newSelectedDate = calendar.date(byAdding: .day, value: dayOffset, to: newWeekStart) ?? newWeekStart

            renderedWeekStart = newWeekStart
            renderedSelectedDate = newSelectedDate
            selectedDate.wrappedValue = newSelectedDate
            rebuildWindow()
            recenter(collectionView)
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
    @Previewable @State var selectedDate = Date()

    VStack(spacing: 16) {
        MiniCalendarHeaderView(selectedDate: $selectedDate)
            .frame(height: 64)

        Text(selectedDate, format: .dateTime.day().month().year())
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
