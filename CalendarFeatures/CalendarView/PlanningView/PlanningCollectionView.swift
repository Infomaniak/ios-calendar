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

private struct PlanningScrollAnchor {
    let date: Date
    let offsetFromTop: CGFloat
}

struct PlanningCollectionView: UIViewRepresentable {
    var planningViewModel: PlanningViewModel
    let nextEventCardViewModel: NextEventCardViewModel

    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: context.coordinator.makeLayout()
        )
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.showsVerticalScrollIndicator = false
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
        coordinator.applyContentInsetTop(
            nextEventCardViewModel.size.height + IKPadding.medium,
            in: collectionView
        )
        coordinator.applyWithAnchorRestoration(planningViewModel.days, in: collectionView)

        if let target = planningViewModel.scrollTarget {
            coordinator.scroll(to: target, in: collectionView)
            Task { @MainActor in
                planningViewModel.scrollTarget = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(planningViewModel: planningViewModel, nextEventCardViewModel: nextEventCardViewModel)
    }

    @MainActor
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        private let planningViewModel: PlanningViewModel
        private let nextEventCardViewModel: NextEventCardViewModel

        private let dayHeaderRegistration: UICollectionView.SupplementaryRegistration<PlanningDayHeaderView>
        private let weekHeaderCellRegistration: UICollectionView.CellRegistration<PlanningWeekHeaderCell, Date>
        private let allDayCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>
        private let eventCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>
        private let emptyEventCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Date>

        private var gestureStartOffsetY = CGFloat.zero
        private var gestureStartProgress: CGFloat = 1.0
        private let fullScrollDistance: CGFloat = 100
        private let scrollThreshold: CGFloat = 0.5

        private var days: [PlanningDay] = []
        private var isAdjusting = false
        private var lastScrolledTarget: Date?
        private var pinnedDate: Date?

        private var cellSizeHelper = PlanningCellSizeHelper()

        init(planningViewModel: PlanningViewModel, nextEventCardViewModel: NextEventCardViewModel) {
            self.planningViewModel = planningViewModel
            self.nextEventCardViewModel = nextEventCardViewModel

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

            emptyEventCellRegistration = .init { cell, _, _ in
                cell.contentConfiguration = UIHostingConfiguration { NoEventsCellView() }
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
        }

        // MARK: - Backing store

        private func day(at section: Int) -> PlanningDay {
            days[section]
        }

        private func item(at indexPath: IndexPath) -> PlanningItem {
            let items = days[indexPath.section].items
            return items[indexPath.item]
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
            let item = item(at: indexPath)
            let inset = sectionInset(for: indexPath.section)
            let width = collectionView.bounds.width - inset.right - inset.left

            switch item {
            case .weekHeader:
                return CGSize(width: width, height: PlanningLayoutMetrics.weekHeaderHeight)
            case .empty:
                return CGSize(width: width, height: PlanningLayoutMetrics.eventRowMinHeight)
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
            let day = day(at: section)

            if day.isWeekStart {
                return UIEdgeInsets(
                    top: 0,
                    left: PlanningLayoutMetrics.dayColumnWidth,
                    bottom: IKPadding.large,
                    right: IKPadding.mini
                )
            } else {
                return UIEdgeInsets(
                    top: -PlanningLayoutMetrics.dayHeaderHeight,
                    left: PlanningLayoutMetrics.dayColumnWidth,
                    bottom: IKPadding.huge,
                    right: IKPadding.mini
                )
            }
        }

        // MARK: - Data source

        func numberOfSections(in collectionView: UICollectionView) -> Int {
            days.count
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            day(at: section).items.count
        }

        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            let item = item(at: indexPath)
            switch item {
            case .weekHeader(let date):
                return collectionView.dequeueConfiguredReusableCell(
                    using: weekHeaderCellRegistration,
                    for: indexPath,
                    item: date
                )
            case .empty(let date):
                return collectionView.dequeueConfiguredReusableCell(
                    using: emptyEventCellRegistration,
                    for: indexPath,
                    item: date
                )
            case .event(let event):
                let registration = event.isAllDay ? allDayCellRegistration : eventCellRegistration
                return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: event)
            }
        }

        func collectionView(
            _ collectionView: UICollectionView,
            viewForSupplementaryElementOfKind kind: String,
            at indexPath: IndexPath
        ) -> UICollectionReusableView {
            let header = collectionView.dequeueConfiguredReusableSupplementary(
                using: dayHeaderRegistration,
                for: indexPath
            )
            let date = day(at: indexPath.section).date
            header.configure(date: date)
            return header
        }

        // MARK: - Applying updates

        func applyContentInsetTop(_ newTop: CGFloat, in collectionView: UICollectionView) {
            guard collectionView.contentInset.top != newTop else { return }

            isAdjusting = true
            defer { isAdjusting = false }

            if let pinnedDate {
                collectionView.contentInset.top = newTop
                pin(to: pinnedDate, in: collectionView)
                return
            }

            let anchor = captureAnchor(in: collectionView)
            collectionView.contentInset.top = newTop
            if let anchor {
                restore(anchor: anchor, in: collectionView)
            }
        }

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
            let previousDays = days
            days = target

            guard collectionView.numberOfSections == target.count, previousDays.count == target.count else {
                collectionView.reloadData()
                collectionView.layoutIfNeeded()
                return
            }

            var changedSections = IndexSet()
            for index in target.indices where previousDays[index] != target[index] {
                changedSections.insert(index)
            }

            guard !changedSections.isEmpty else { return }

            UIView.performWithoutAnimation {
                collectionView.reloadSections(changedSections)
                collectionView.layoutIfNeeded()
            }
        }

        private func captureAnchor(in collectionView: UICollectionView) -> PlanningScrollAnchor? {
            guard let topIndexPath = collectionView.indexPathsForVisibleItems.min(),
                  let attributes = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: topIndexPath.section))
            else {
                return nil
            }
            let day = day(at: topIndexPath.section)
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
            if planningViewModel.hasDeliveredEvents,
               planningViewModel.isWithinObserveWindow(date),
               let section = planningViewModel.sectionIndex(for: date),
               let indexPath = scrollIndexPath(forSectionContaining: section, targetDate: date) {
                collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
            } else if lastScrolledTarget != date {
                lastScrolledTarget = date
                pinnedDate = date
                scrollToFarAway(date: date, in: collectionView)
            }
        }

        private func scrollToFarAway(date: Date, in collectionView: UICollectionView) {
            planningViewModel.refreshObserveWindow(around: date)

            isAdjusting = true
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

        // MARK: - UIScrollViewDelegate

        func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
            return false
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            pinnedDate = nil

            gestureStartOffsetY = scrollView.contentOffset.y
            gestureStartProgress = nextEventCardViewModel.scrollProgress
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            updateObserveWindowIfNeeded(scrollView: scrollView)
            computeScrollProgress(scrollView: scrollView)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            guard !decelerate else { return }
            commitScrollProgress()
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            commitScrollProgress()
        }

        private func commitScrollProgress() {
            let target = nextEventCardViewModel.scrollProgress > scrollThreshold ? 1.0 : 0.0
            withAnimation(.spring(duration: 0.2)) {
                nextEventCardViewModel.scrollProgress = target
            }
        }

        private func computeScrollProgress(scrollView: UIScrollView) {
            guard scrollView.isDragging || scrollView.isDecelerating else {
                return
            }

            let delta = scrollView.contentOffset.y - gestureStartOffsetY
            let newProgress = gestureStartProgress - delta / fullScrollDistance
            nextEventCardViewModel.scrollProgress = min(max(newProgress, 0), 1)
        }

        private func updateObserveWindowIfNeeded(scrollView: UIScrollView) {
            guard !isAdjusting, let collectionView = scrollView as? UICollectionView else { return }
            guard let topIndexPath = collectionView.indexPathsForVisibleItems.min() else {
                return
            }
            let topDate = day(at: topIndexPath.section).date
            planningViewModel.refreshObserveWindowIfNeeded(around: topDate)
        }
    }
}

#Preview {
    PlanningCollectionView(
        planningViewModel: PlanningViewModel(calendarAccounts: [:]),
        nextEventCardViewModel: NextEventCardViewModel()
    )
    .ignoresSafeArea()
}
