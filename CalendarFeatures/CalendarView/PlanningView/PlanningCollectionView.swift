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
import DifferenceKit
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
        collectionView.dataSource = context.coordinator
        context.coordinator.reset(to: planningViewModel.sections)
        collectionView.reloadData()

        if #available(iOS 26.0, *) {
            // Remove the effect since we will use a custom header
            collectionView.topEdgeEffect.isHidden = true
        }

        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        let coordinator = context.coordinator
        coordinator.applyWithAnchorRestoration(planningViewModel.sections, in: collectionView)

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
    class Coordinator: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
        /// How close (in weeks) the visible range must get to a window edge before the
        /// window recycles. Bump to `3` to start loading earlier at the cost of more
        /// frequent shifts.
        private let edgeTriggerWeeks = 2
        private let reloadChangeThreshold = 100

        private let planningViewModel: PlanningViewModel

        private let dayHeaderRegistration: UICollectionView.SupplementaryRegistration<PlanningDayHeaderView>
        private let weekHeaderCellRegistration: UICollectionView.CellRegistration<PlanningWeekHeaderCell, Date>
        private let allDayCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>
        private let eventCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>

        private var sections: PlanningViewDifference = []
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
            }

            eventCellRegistration = .init { cell, _, event in
                cell.contentConfiguration = UIHostingConfiguration {
                    PlanningEventView(event: event)
                }
                .margins(.all, 0)
                .minSize(height: PlanningLayoutMetrics.eventRowMinHeight)
            }

            super.init()
        }

        // MARK: - Backing store

        func reset(to sections: PlanningViewDifference) {
            self.sections = sections
        }

        private func day(at section: Int) -> PlanningDay? {
            sections.indices.contains(section) ? sections[section].model : nil
        }

        private func item(at indexPath: IndexPath) -> PlanningItem? {
            guard sections.indices.contains(indexPath.section) else { return nil }
            let elements = sections[indexPath.section].elements
            return elements.indices.contains(indexPath.item) ? elements[indexPath.item] : nil
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

        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return sections.count
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return sections.indices.contains(section) ? sections[section].elements.count : 0
        }

        func collectionView(
            _ collectionView: UICollectionView,
            viewForSupplementaryElementOfKind kind: String,
            at indexPath: IndexPath
        ) -> UICollectionReusableView {
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: dayHeaderRegistration, for: indexPath)
            if let date = day(at: indexPath.section)?.date {
                header.configure(date: date)
            }
            return header
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            switch item(at: indexPath) {
            case .weekHeader(let date):
                return collectionView.dequeueConfiguredReusableCell(
                    using: weekHeaderCellRegistration,
                    for: indexPath,
                    item: date
                )
            case .event(let event):
                let registration = event.isAllDay ? allDayCellRegistration : eventCellRegistration
                return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: event)
            case nil:
                return UICollectionViewCell()
            }
        }

        // MARK: - Applying updates

        /// Applies `target` to the collection view while keeping the topmost visible day
        /// pinned in place, so neither recycling shifts nor streamed content jump the scroll.
        func applyWithAnchorRestoration(_ target: PlanningViewDifference, in collectionView: UICollectionView) {
            let changeset = StagedChangeset(source: sections, target: target)
            guard !changeset.isEmpty else {
                sections = target
                return
            }

            isAdjusting = true
            let anchor = captureAnchor(in: collectionView)

            UIView.performWithoutAnimation {
                collectionView.reload(
                    using: changeset,
                    interrupt: { $0.changeCount > self.reloadChangeThreshold },
                    setData: { data in self.sections = data }
                )
                collectionView.layoutIfNeeded()
            }

            if let anchor {
                restore(anchor: anchor, in: collectionView)
            }
            isAdjusting = false
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
            guard let section = sections.firstIndex(where: { $0.model.date == anchor.date }),
                  !sections[section].elements.isEmpty,
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

        // MARK: - Scrolling to a date

        func scroll(to date: Date, animated: Bool, in collectionView: UICollectionView) {
            if planningViewModel.sectionIndex(for: date) == nil {
                planningViewModel.reAnchor(around: date)
                UIView.performWithoutAnimation {
                    sections = planningViewModel.sections
                    collectionView.reloadData()
                    collectionView.layoutIfNeeded()
                }
            }

            guard let section = planningViewModel.sectionIndex(for: date),
                  let indexPath = scrollIndexPath(forSectionContaining: section) else {
                return
            }
            collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
        }

        private func scrollIndexPath(forSectionContaining section: Int) -> IndexPath? {
            for candidate in stride(from: section, through: max(0, section - 6), by: -1) {
                if sections.indices.contains(candidate), !sections[candidate].elements.isEmpty {
                    return IndexPath(item: 0, section: candidate)
                }
            }
            for candidate in section ..< sections.count where !sections[candidate].elements.isEmpty {
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
            let lastSection = sections.count - 1

            if maxSection >= lastSection - triggerDays {
                planningViewModel.shiftForward()
                applyWithAnchorRestoration(planningViewModel.sections, in: collectionView)
            } else if minSection <= triggerDays {
                planningViewModel.shiftBackward()
                applyWithAnchorRestoration(planningViewModel.sections, in: collectionView)
            }
        }
    }
}

#Preview {
    PlanningCollectionView(planningViewModel: PlanningViewModel())
        .ignoresSafeArea()
}
