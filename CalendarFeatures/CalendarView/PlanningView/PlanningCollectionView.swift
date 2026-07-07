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

import CalendarCoreUI
import DesignSystem
import Foundation
import SwiftUI
import UIKit

enum PlanningLayoutMetrics {
    static let dayColumnWidth: CGFloat = 64
    static let eventRowHeight: CGFloat = 48
    static let eventRowMinHeight: CGFloat = 20
    static let dayHeaderHeight: CGFloat = 64
    static let weekHeaderHeight: CGFloat = 16
}

/// Reference used to keep the topmost visible day pinned across collection view updates.
private struct PlanningScrollAnchor {
    let date: Date
    let offsetFromTop: CGFloat
}

struct PlanningCollectionView: UIViewRepresentable {
    var planningViewModel: PlanningViewModel

    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: context.coordinator.makeLayout()
        )
        collectionView.delegate = context.coordinator
        collectionView.showsVerticalScrollIndicator = false
        context.coordinator.makeDataSource(for: collectionView)
        context.coordinator.apply(planningViewModel.days, in: collectionView)

        if #available(iOS 26.0, *) {
            // Remove the effect since we will use a custom header
            collectionView.topEdgeEffect.isHidden = true
        }

        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        let coordinator = context.coordinator
        coordinator.applyWithAnchorRestoration(planningViewModel.days, in: collectionView)

        guard collectionView.bounds.height > 0 else { return }

        if let target = planningViewModel.scrollTarget {
            coordinator.scroll(to: target, animated: context.transaction.animation != nil, in: collectionView)
            Task { @MainActor in
                planningViewModel.scrollTarget = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(planningViewModel: planningViewModel)
    }

    @MainActor
    class Coordinator: NSObject, UICollectionViewDelegateFlowLayout {
        private let edgeTriggerWeeks = 2

        private let planningViewModel: PlanningViewModel

        private var dataSource: UICollectionViewDiffableDataSource<Date, PlanningItem>!

        private let dayHeaderRegistration: UICollectionView.SupplementaryRegistration<PlanningDayHeaderView>
        private let weekHeaderCellRegistration: UICollectionView.CellRegistration<PlanningWeekHeaderCell, Date>
        private let allDayCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>
        private let eventCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>

        private var days: [PlanningDay] = []
        private var isAdjusting = false

        init(planningViewModel: PlanningViewModel) {
            self.planningViewModel = planningViewModel

            dayHeaderRegistration = .init(elementKind: UICollectionView.elementKindSectionHeader) { _, _, _ in }

            weekHeaderCellRegistration = .init { cell, _, date in
                cell.configure(date: date)
            }

            allDayCellRegistration = .init { cell, _, event in
                cell.contentConfiguration = UIHostingConfiguration {
                    PlanningDayEventView(event: event)
                }
                .margins(.all, 0)
                .minSize(height: PlanningLayoutMetrics.eventRowMinHeight)

                cell.configurationUpdateHandler = { cell, _ in
                    cell.backgroundConfiguration = .clear()
                }
            }

            eventCellRegistration = .init { cell, _, event in
                cell.contentConfiguration = UIHostingConfiguration {
                    PlanningEventView(event: event)
                }
                .margins(.all, 0)
                .minSize(height: PlanningLayoutMetrics.eventRowMinHeight)

                cell.configurationUpdateHandler = { cell, _ in
                    cell.backgroundConfiguration = .clear()
                }
            }

            super.init()
        }

        // MARK: - Backing store

        private func day(at section: Int) -> PlanningDay? {
            days.indices.contains(section) ? days[section] : nil
        }

        private func item(at indexPath: IndexPath) -> PlanningItem? {
            guard days.indices.contains(indexPath.section) else { return nil }
            let items = days[indexPath.section].items
            return items.indices.contains(indexPath.item) ? items[indexPath.item] : nil
        }

        // MARK: - Layout

        func makeLayout() -> UICollectionViewFlowLayout {
            let layout = UICollectionViewFlowLayout()
            layout.minimumLineSpacing = IKPadding.mini
            layout.minimumInteritemSpacing = 0
            layout.sectionHeadersPinToVisibleBounds = true
            return layout
        }

        // MARK: - Flow layout delegate

        func collectionView(
            _ collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
            guard let item = item(at: indexPath) else { return .zero }
            let inset = sectionInset(for: indexPath.section)
            let width = collectionView.bounds.width - inset.right - inset.left

            switch item {
            case .weekHeader:
                return CGSize(width: width, height: PlanningLayoutMetrics.weekHeaderHeight)
            case .event(let event):
                let height = event.isAllDay
                    ? PlanningLayoutMetrics.eventRowHeight
                    : PlanningLayoutMetrics.eventRowHeight + event.bottomPadding
                return CGSize(width: width, height: height)
            }
        }

        func collectionView(
            _ collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            referenceSizeForHeaderInSection section: Int
        ) -> CGSize {
            guard let day = day(at: section), !day.events.isEmpty else {
                return .zero
            }
            return CGSize(width: PlanningLayoutMetrics.dayColumnWidth, height: PlanningLayoutMetrics.dayHeaderHeight)
        }

        func collectionView(
            _ collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            insetForSectionAt section: Int
        ) -> UIEdgeInsets {
            return sectionInset(for: section)
        }

        private func sectionInset(for section: Int) -> UIEdgeInsets {
            guard let day = day(at: section) else { return .zero }

            if !day.events.isEmpty {
                return UIEdgeInsets(
                    top: -PlanningLayoutMetrics.dayHeaderHeight,
                    left: PlanningLayoutMetrics.dayColumnWidth,
                    bottom: IKPadding.large,
                    right: IKPadding.mini
                )
            } else if day.isWeekStart {
                return UIEdgeInsets(
                    top: 0,
                    left: PlanningLayoutMetrics.dayColumnWidth,
                    bottom: IKPadding.large,
                    right: IKPadding.mini
                )
            } else {
                return .zero
            }
        }

        // MARK: - Data source

        func makeDataSource(for collectionView: UICollectionView) {
            let dataSource = UICollectionViewDiffableDataSource<Date, PlanningItem>(
                collectionView: collectionView
            ) { [weak self] collectionView, indexPath, item in
                guard let self else { return UICollectionViewCell() }
                switch item {
                case .weekHeader(let date):
                    return collectionView.dequeueConfiguredReusableCell(
                        using: weekHeaderCellRegistration,
                        for: indexPath,
                        item: date
                    )
                case .event(let event):
                    let registration = event.isAllDay ? allDayCellRegistration : eventCellRegistration
                    return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: event)
                }
            }

            dataSource.supplementaryViewProvider = { [weak self] collectionView, _, indexPath in
                guard let self else { return nil }
                let header = collectionView.dequeueConfiguredReusableSupplementary(
                    using: dayHeaderRegistration,
                    for: indexPath
                )
                if let date = day(at: indexPath.section)?.date {
                    header.configure(date: date)
                }
                return header
            }

            self.dataSource = dataSource
        }

        private func makeSnapshot(from days: [PlanningDay]) -> NSDiffableDataSourceSnapshot<Date, PlanningItem> {
            var snapshot = NSDiffableDataSourceSnapshot<Date, PlanningItem>()
            snapshot.appendSections(days.map(\.date))
            for day in days {
                snapshot.appendItems(day.items, toSection: day.date)
            }
            return snapshot
        }

        // MARK: - Applying updates

        func applyWithAnchorRestoration(_ target: [PlanningDay], in collectionView: UICollectionView) {
            guard days != target else { return }

            isAdjusting = true
            let anchor = captureAnchor(in: collectionView)

            apply(target, in: collectionView)

            if let anchor {
                restore(anchor: anchor, in: collectionView)
            }
            isAdjusting = false
        }

        func apply(_ target: [PlanningDay], in collectionView: UICollectionView) {
            days = target
            let snapshot = makeSnapshot(from: target)
            UIView.performWithoutAnimation {
                dataSource.apply(snapshot, animatingDifferences: false)
                collectionView.layoutIfNeeded()
            }
        }

        private func captureAnchor(in collectionView: UICollectionView) -> PlanningScrollAnchor? {
            guard let topIndexPath = collectionView.indexPathsForVisibleItems.min(),
                  let day = day(at: topIndexPath.section),
                  let attributes = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: topIndexPath.section))
            else {
                return nil
            }
            return PlanningScrollAnchor(date: day.date, offsetFromTop: attributes.frame.minY - collectionView.contentOffset.y)
        }

        private func restore(anchor: PlanningScrollAnchor, in collectionView: UICollectionView) {
            guard let section = days.firstIndex(where: { $0.date == anchor.date }),
                  !days[section].items.isEmpty,
                  let attributes = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: section))
            else {
                return
            }

            let targetY = attributes.frame.minY - anchor.offsetFromTop
            let minOffset = -collectionView.adjustedContentInset.top
            let maxOffset = max(
                minOffset,
                collectionView.contentSize.height - collectionView.bounds.height + collectionView.adjustedContentInset.bottom
            )
            collectionView.contentOffset.y = min(max(targetY, minOffset), maxOffset)
        }

        func scroll(to date: Date, animated: Bool, in collectionView: UICollectionView) {
            if planningViewModel.sectionIndex(for: date) == nil {
                planningViewModel.reAnchor(around: date)
                apply(planningViewModel.days, in: collectionView)
            }

            guard let section = planningViewModel.sectionIndex(for: date),
                  let indexPath = scrollIndexPath(forSectionContaining: section) else {
                return
            }
            collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
        }

        private func scrollIndexPath(forSectionContaining section: Int) -> IndexPath? {
            for candidate in stride(from: section, through: max(0, section - 6), by: -1) {
                if days.indices.contains(candidate), !days[candidate].items.isEmpty {
                    return IndexPath(item: 0, section: candidate)
                }
            }
            for candidate in section ..< days.count where !days[candidate].items.isEmpty {
                return IndexPath(item: 0, section: candidate)
            }
            return nil
        }

        // MARK: - Scroll observation

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isAdjusting, let collectionView = scrollView as? UICollectionView else { return }

            let visibleSections = collectionView.indexPathsForVisibleItems.map(\.section)
            guard let minSection = visibleSections.min(), let maxSection = visibleSections.max() else { return }

            let triggerDays = edgeTriggerWeeks * 7
            let lastSection = days.count - 1

            if maxSection >= lastSection - triggerDays {
                planningViewModel.shiftForward()
                applyWithAnchorRestoration(planningViewModel.days, in: collectionView)
            } else if minSection <= triggerDays {
                planningViewModel.shiftBackward()
                applyWithAnchorRestoration(planningViewModel.days, in: collectionView)
            }
        }
    }
}

#Preview {
    PlanningCollectionView(planningViewModel: PlanningViewModel())
        .ignoresSafeArea()
}
