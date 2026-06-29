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
    static let emptyRowHeight: CGFloat = 8
    static let eventRowHeight: CGFloat = 48
    static let eventRowMinHeight: CGFloat = 20
    static let dayHeaderHeight: CGFloat = 64
    static let weekHeaderHeight: CGFloat = 32

    static let dayHeaderKind = "PlanningDayHeaderKind"
    static let weekHeaderKind = "PlanningWeekHeaderKind"
}

enum PlanningItemId: Hashable {
    case event(id: String)
    case empty(Date)
}

enum PlanningItemContent: Hashable {
    case event
    case empty
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
        context.coordinator.applySnapshot(animated: animated, collectionView: collectionView)

        guard let target = planningViewModel.scrollTarget else { return }
        context.coordinator.scrollToStartOfDay(date: target, animated: animated, for: collectionView)
        Task { @MainActor in
            planningViewModel.scrollTarget = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(planningViewModel: planningViewModel)
    }

    class Coordinator: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
        private var datasource: UICollectionViewDiffableDataSource<Date, PlanningItemId>?

        private let planningViewModel: PlanningViewModel

        let dayHeaderRegistration: UICollectionView.SupplementaryRegistration<PlanningDayHeaderView>
        let weekHeaderRegistration: UICollectionView.SupplementaryRegistration<PlanningWeekHeaderView>

        let emptyCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, PlanningItemContent>
        let allDayCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>
        let eventCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, CalendarCoreUI.UIEvent>

        init(planningViewModel: PlanningViewModel) {
            self.planningViewModel = planningViewModel

            dayHeaderRegistration = UICollectionView.SupplementaryRegistration<PlanningDayHeaderView>(
                elementKind: PlanningLayoutMetrics.dayHeaderKind
            ) { headerView, _, indexPath in
                guard indexPath.section < planningViewModel.totalDays else { return }
                headerView.configure(date: planningViewModel.getPlanningDayAtIndex(indexPath.section).date)
            }

            weekHeaderRegistration = UICollectionView.SupplementaryRegistration<PlanningWeekHeaderView>(
                elementKind: PlanningLayoutMetrics.weekHeaderKind
            ) { headerView, _, indexPath in
                guard indexPath.section < planningViewModel.totalDays else { return }
                headerView.configure(date: planningViewModel.getPlanningDayAtIndex(indexPath.section).date)
            }

            emptyCellRegistration = .init { cell, _, _ in
                cell.contentConfiguration = cell.defaultContentConfiguration()
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

        func makeLayout() -> UICollectionViewCompositionalLayout {
            let configuration = UICollectionViewCompositionalLayoutConfiguration()
            configuration.interSectionSpacing = 0

            return UICollectionViewCompositionalLayout(
                section: Coordinator.makeDaySection(
                    showsWeekHeader: true,
                    showsDayHeader: true,
                    hasNoEvents: false
                ),
                configuration: configuration
            )
        }

        private func shouldShowDayHeader(at sectionIndex: Int) -> Bool {
            return !planningViewModel.getPlanningDayAtIndex(sectionIndex).events.isEmpty
        }

        private func shouldShowWeekHeader(at sectionIndex: Int) -> Bool {
            guard sectionIndex < planningViewModel.totalDays else { return false }
            guard sectionIndex > 0 else { return true }

            let currentDate = planningViewModel.getPlanningDayAtIndex(sectionIndex).date
            let previousDate = planningViewModel.getPlanningDayAtIndex(sectionIndex - 1).date
            return !Calendar.current.isDate(currentDate, equalTo: previousDate, toGranularity: .weekOfYear)
        }

        private static func makeDaySection(showsWeekHeader: Bool,
                                           showsDayHeader: Bool,
                                           hasNoEvents: Bool) -> NSCollectionLayoutSection {
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: hasNoEvents ?
                    .absolute(PlanningLayoutMetrics.emptyRowHeight) : .estimated(PlanningLayoutMetrics.eventRowHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets.zero

            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets.zero

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = IKPadding.mini
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: PlanningLayoutMetrics.dayColumnWidth,
                bottom: 0,
                trailing: 0
            )

            var boundarySupplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()

            if showsWeekHeader {
                let weekHeaderSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(PlanningLayoutMetrics.weekHeaderHeight)
                )
                let weekHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: weekHeaderSize,
                    elementKind: PlanningLayoutMetrics.weekHeaderKind,
                    alignment: .topLeading
                )
                weekHeader.zIndex = 2
                boundarySupplementaryItems.append(weekHeader)
            }

            if showsDayHeader {
                let dayHeaderSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(PlanningLayoutMetrics.dayColumnWidth),
                    heightDimension: .absolute(PlanningLayoutMetrics.dayHeaderHeight)
                )
                let dayHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: dayHeaderSize,
                    elementKind: PlanningLayoutMetrics.dayHeaderKind,
                    alignment: .topLeading,
                    absoluteOffset: CGPoint(x: -PlanningLayoutMetrics.dayColumnWidth, y: 0)
                )
                dayHeader.pinToVisibleBounds = true
                dayHeader.extendsBoundary = false
                dayHeader.zIndex = 1

                boundarySupplementaryItems.append(dayHeader)
            }

            section.boundarySupplementaryItems = boundarySupplementaryItems

            return section
        }

        // MARK: - Data source

        func collectionView(
            _ collectionView: UICollectionView,
            viewForSupplementaryElementOfKind kind: String,
            at indexPath: IndexPath
        ) -> UICollectionReusableView {
            switch kind {
            case PlanningLayoutMetrics.weekHeaderKind:
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: weekHeaderRegistration,
                    for: indexPath
                )
            default:
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: dayHeaderRegistration,
                    for: indexPath
                )
            }
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            planningViewModel.getPlanningDayAtIndex(section).events.count
        }

        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return planningViewModel.totalDays
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let day = planningViewModel.getPlanningDayAtIndex(indexPath.section)
            guard !day.events.isEmpty else {
                return collectionView.dequeueConfiguredReusableCell(
                    using: emptyCellRegistration,
                    for: indexPath,
                    item: .empty
                )
            }

            let event = day.events[indexPath.item]

            let registration = event.isAllDay ? allDayCellRegistration : eventCellRegistration
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: event)
        }

        func applySnapshot(animated: Bool, collectionView: UICollectionView) {
            collectionView.reloadData()
        }

        func scrollToStartOfDay(date: Date, animated: Bool, for collectionView: UICollectionView) {
            /*let indexPath = IndexPath(item: 0, section: planningViewModel.totalDays / 2)
            collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)*/
        }
    }
}

#Preview {
    PlanningCollectionView(planningViewModel: PlanningViewModel())
        .ignoresSafeArea()
}
