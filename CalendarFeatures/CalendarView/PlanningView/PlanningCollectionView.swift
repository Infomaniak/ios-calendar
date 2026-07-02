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
import Collections
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

struct PlanningCollectionView: UIViewRepresentable {
    @ObservedObject var planningViewModel: PlanningViewModel

    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: context.coordinator.makeLayout()
        )
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator

        if #available(iOS 26.0, *) {
            // Remove the effect since we will use a custom header
            collectionView.topEdgeEffect.isHidden = true
        }

        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        let animated = context.transaction.animation != nil
        if let differences = planningViewModel.lastDifference {
            context.coordinator.applyDifferences(differences, collectionView: collectionView)
            Task { @MainActor in
                planningViewModel.lastDifference = nil
            }
        }

        guard let target = planningViewModel.scrollTarget else { return }
        context.coordinator.scrollToStartOfDay(date: target, animated: animated, for: collectionView)
        Task { @MainActor in
            planningViewModel.scrollTarget = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(planningViewModel: planningViewModel)
    }

    class Coordinator: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
        private let planningViewModel: PlanningViewModel

        let dayHeaderRegistration: UICollectionView.SupplementaryRegistration<PlanningDayHeaderView>

        let weekHeaderCellRegistration: UICollectionView.CellRegistration<PlanningWeekHeaderCell, Date>
        let allDayCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>
        let eventCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>

        init(planningViewModel: PlanningViewModel) {
            self.planningViewModel = planningViewModel

            dayHeaderRegistration = .init(elementKind: UICollectionView.elementKindSectionHeader) { headerView, _, indexPath in
                guard indexPath.section < planningViewModel.totalDays else { return }
                headerView.configure(date: planningViewModel.getPlanningDayAtIndex(indexPath.section).date)
            }

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
            let day = planningViewModel.getPlanningDayAtIndex(indexPath.section)
            let inset = sectionInset(for: indexPath.section)
            let width = collectionView.bounds.width - inset.right - inset.left

            if day.isWeekStart, indexPath.item == 0 {
                return CGSize(width: width, height: PlanningLayoutMetrics.weekHeaderHeight)
            }

            let eventIndex = day.isWeekStart ? indexPath.item - 1 : indexPath.item
            let event = day.events[eventIndex]
            if event.isAllDay {
                return CGSize(width: width, height: PlanningLayoutMetrics.eventRowHeight)
            } else {
                return CGSize(width: width, height: PlanningLayoutMetrics.eventRowHeight + event.bottomPadding)
            }
        }

        func collectionView(
            _ collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            referenceSizeForHeaderInSection section: Int
        ) -> CGSize {
            let day = planningViewModel.getPlanningDayAtIndex(section)
            guard !day.events.isEmpty else {
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
            let day = planningViewModel.getPlanningDayAtIndex(section)

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

        func collectionView(
            _ collectionView: UICollectionView,
            viewForSupplementaryElementOfKind kind: String,
            at indexPath: IndexPath
        ) -> UICollectionReusableView {
            return collectionView.dequeueConfiguredReusableSupplementary(
                using: dayHeaderRegistration,
                for: indexPath
            )
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            let day = planningViewModel.getPlanningDayAtIndex(section)
            guard !day.events.isEmpty else {
                return day.isWeekStart ? 1 : 0
            }
            let weekHeaderCount = day.isWeekStart ? 1 : 0
            return day.events.count + weekHeaderCount
        }

        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return planningViewModel.totalDays
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let day = planningViewModel.getPlanningDayAtIndex(indexPath.section)

            if day.isWeekStart, indexPath.item == 0 {
                return collectionView.dequeueConfiguredReusableCell(
                    using: weekHeaderCellRegistration,
                    for: indexPath,
                    item: day.date
                )
            }

            let eventIndex = day.isWeekStart ? indexPath.item - 1 : indexPath.item
            let event = day.events[eventIndex]

            let registration = event.isAllDay ? allDayCellRegistration : eventCellRegistration
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: event)
        }

        func applyDifferences(_ differences: PlanningViewDifference, collectionView: UICollectionView) {
            collectionView.performBatchUpdates {
                collectionView.deleteItems(at: differences.removed)
                collectionView.insertItems(at: differences.added)
                collectionView.reloadItems(at: differences.updated)
            }
        }

        func scrollToStartOfDay(date: Date, animated: Bool, for collectionView: UICollectionView) {
            let indexPath = IndexPath(item: 0, section: planningViewModel.totalDays / 2)
            collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
        }
    }
}

#Preview {
    PlanningCollectionView(planningViewModel: PlanningViewModel())
        .ignoresSafeArea()
}
