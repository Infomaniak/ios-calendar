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
        collectionView.registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { collectionView, _ in
            context.coordinator.handleContentSizeCategoryChange(in: collectionView)
        }

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

        coordinator.ensureScrollableContent(in: collectionView)

        if let target = planningViewModel.scrollTarget {
            coordinator.scroll(to: target, in: collectionView)
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
        private let recycleEdgeTrigger: CGFloat = 88

        private let planningViewModel: PlanningViewModel

        private var dataSource: UICollectionViewDiffableDataSource<Date, PlanningItem>!

        private let dayHeaderRegistration: UICollectionView.SupplementaryRegistration<PlanningDayHeaderView>
        private let weekHeaderCellRegistration: UICollectionView.CellRegistration<PlanningWeekHeaderCell, Date>
        private let allDayCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>
        private let eventCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>

        private var days: [PlanningDay] = []
        private var isAdjusting = false
        private var lastScrolledTarget: Date?
        private var pinnedDate: Date?

        private var cellSizeHelper = PlanningCellSizeHelper()

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

        func handleContentSizeCategoryChange(in collectionView: UICollectionView) {
            cellSizeHelper = PlanningCellSizeHelper()
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
            ensureScrollableContent(in: collectionView)
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
                let height = cellSizeHelper.heightForCell(event: event)
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
            defer { isAdjusting = false }

            if let pinnedDate {
                apply(target, in: collectionView)
                pin(to: pinnedDate, in: collectionView)
                return
            }

            let anchor = captureAnchor(in: collectionView)
            apply(target, in: collectionView)
            if let anchor {
                restore(anchor: anchor, in: collectionView)
            }
        }

        func apply(_ target: [PlanningDay], in collectionView: UICollectionView) {
            days = target
            let snapshot = makeSnapshot(from: target)
            UIView.performWithoutAnimation {
                dataSource.apply(snapshot, animatingDifferences: false)
                collectionView.layoutIfNeeded()
            }
        }

        func ensureScrollableContent(in collectionView: UICollectionView) {
            guard collectionView.bounds.height > 0 else { return }

            var iterations = 0
            while !hasScrollBuffer(collectionView), planningViewModel.growWindow() {
                applyWithAnchorRestoration(planningViewModel.days, in: collectionView)
                collectionView.layoutIfNeeded()

                iterations += 1
                if iterations > PlanningViewModel.maxWindowWeeks {
                    break
                }
            }
        }

        private func viewportHeight(of collectionView: UICollectionView) -> CGFloat {
            let insets = collectionView.adjustedContentInset
            return collectionView.bounds.height - insets.top - insets.bottom
        }

        private func isScrollable(_ collectionView: UICollectionView) -> Bool {
            collectionView.contentSize.height > viewportHeight(of: collectionView)
        }

        private func hasScrollBuffer(_ collectionView: UICollectionView) -> Bool {
            collectionView.contentSize.height > viewportHeight(of: collectionView) + recycleEdgeTrigger * 2 + 1
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

        func scroll(to date: Date, in collectionView: UICollectionView) {
            if let section = planningViewModel.sectionIndex(for: date),
               let indexPath = scrollIndexPath(forSectionContaining: section, targetDate: date) {
                collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
            } else if lastScrolledTarget != date {
                lastScrolledTarget = date
                pinnedDate = date
                scrollToFarAway(date: date, in: collectionView)
            }
        }

        private func scrollToFarAway(date: Date, in collectionView: UICollectionView) {
            planningViewModel.reAnchor(around: date)

            isAdjusting = true
            apply(planningViewModel.days, in: collectionView)

            ensureScrollableContent(in: collectionView)

            pin(to: date, in: collectionView)
            isAdjusting = false
        }

        private func pin(to date: Date, in collectionView: UICollectionView) {
            collectionView.layoutIfNeeded()
            guard let section = planningViewModel.sectionIndex(for: date),
                  let indexPath = scrollIndexPath(forSectionContaining: section, targetDate: date) else {
                return
            }
            collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }

        private func scrollIndexPath(forSectionContaining section: Int, targetDate: Date) -> IndexPath? {
            if let indexPath = findIndexPathFor(targetDate: targetDate, in: section) {
                return indexPath
            } else if let indexPath = findNearestIndexPathFor(targetDate: targetDate, in: section) {
                return indexPath
            } else {
                return nil
            }
        }

        private func findIndexPathFor(targetDate: Date, in section: Int) -> IndexPath? {
            for candidate in max(0, section) ..< days.count where !days[candidate].items.isEmpty {
                return IndexPath(item: itemIndex(in: candidate, forTargetDate: targetDate), section: candidate)
            }

            return nil
        }

        private func findNearestIndexPathFor(targetDate: Date, in section: Int) -> IndexPath? {
            for candidate in stride(from: section - 1, through: 0, by: -1)
                where days.indices.contains(candidate) && !days[candidate].items.isEmpty {
                return IndexPath(item: itemIndex(in: candidate, forTargetDate: targetDate), section: candidate)
            }

            return nil
        }

        private func itemIndex(in section: Int, forTargetDate targetDate: Date) -> Int {
            let items = days[section].items
            let matchIndex = items.firstIndex { item in
                guard case .event(let event) = item else { return false }
                return event.endDate > targetDate
            }
            return matchIndex ?? 0
        }

        // MARK: - Scroll observation

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            pinnedDate = nil
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isAdjusting, let collectionView = scrollView as? UICollectionView else { return }
            guard isScrollable(collectionView) else { return }

            let insets = collectionView.adjustedContentInset
            let offsetFromTop = collectionView.contentOffset.y + insets.top
            let distanceToBottom = collectionView.contentSize.height
                - (collectionView.contentOffset.y + collectionView.bounds.height - insets.bottom)

            if distanceToBottom <= recycleEdgeTrigger, distanceToBottom <= offsetFromTop {
                planningViewModel.shiftForward()
                applyWithAnchorRestoration(planningViewModel.days, in: collectionView)
            } else if offsetFromTop <= recycleEdgeTrigger {
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
