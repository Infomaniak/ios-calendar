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

        context.coordinator.setupDatasource(for: collectionView)

        if #available(iOS 26.0, *) {
            // Remove the effect since we will use a custom header
            collectionView.topEdgeEffect.isHidden = true
        }

        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        let animated = context.transaction.animation != nil
        context.coordinator.applySnapshot(animated: animated)

        guard let target = planningViewModel.scrollTarget else { return }
        context.coordinator.scrollToStartOfDay(date: target, animated: animated, for: collectionView)
        Task { @MainActor in
            planningViewModel.scrollTarget = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(planningViewModel: planningViewModel)
    }

    class Coordinator: NSObject, UICollectionViewDelegate {
        private var datasource: UICollectionViewDiffableDataSource<Date, PlanningItemId>?

        private let planningViewModel: PlanningViewModel
        private var planningDays: OrderedDictionary<Date, PlanningDay> {
            return planningViewModel.planningDays
        }

        init(planningViewModel: PlanningViewModel) {
            self.planningViewModel = planningViewModel
            super.init()
        }

        // MARK: - Layout

        func makeLayout() -> UICollectionViewCompositionalLayout {
            let configuration = UICollectionViewCompositionalLayoutConfiguration()
            configuration.interSectionSpacing = 0

            return UICollectionViewCompositionalLayout(
                sectionProvider: { [weak self] sectionIndex, _ in
                    let showsWeekHeader = self?.shouldShowWeekHeader(at: sectionIndex) ?? false
                    let showsDayHeader = self?.shouldShowDayHeader(at: sectionIndex) ?? false
                    let hasNoEvents = self?.planningDays.values[sectionIndex].events.isEmpty ?? true
                    return Coordinator.makeDaySection(
                        showsWeekHeader: showsWeekHeader,
                        showsDayHeader: showsDayHeader,
                        hasNoEvents: hasNoEvents
                    )
                },
                configuration: configuration
            )
        }

        private func shouldShowDayHeader(at sectionIndex: Int) -> Bool {
            return !planningDays.values[sectionIndex].events.isEmpty
        }

        private func shouldShowWeekHeader(at sectionIndex: Int) -> Bool {
            guard sectionIndex < planningDays.count else { return false }
            guard sectionIndex > 0 else { return true }

            let currentDate = planningDays.keys[sectionIndex]
            let previousDate = planningDays.keys[sectionIndex - 1]
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

        func setupDatasource(for collectionView: UICollectionView) {
            let emptyCellRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell, PlanningItemContent
            > { cell, _, _ in
                cell.contentConfiguration = cell.defaultContentConfiguration()
            }

            let allDayCellRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell, CalendarCoreUI.UIEvent
            > { cell, _, event in
                cell.contentConfiguration = UIHostingConfiguration {
                    PlanningDayEventView(event: event)
                }
                .margins(.all, 0)
                .minSize(height: PlanningLayoutMetrics.eventRowMinHeight)
            }

            let eventCellRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell, CalendarCoreUI.UIEvent
            > { cell, _, event in
                cell.contentConfiguration = UIHostingConfiguration {
                    PlanningEventView(event: event)
                }
                .margins(.all, 0)
                .minSize(height: PlanningLayoutMetrics.eventRowMinHeight)
            }

            let dayHeaderRegistration = UICollectionView.SupplementaryRegistration<PlanningDayHeaderView>(
                elementKind: PlanningLayoutMetrics.dayHeaderKind
            ) { [weak self] headerView, _, indexPath in
                guard let self, indexPath.section < planningDays.count else { return }
                headerView.configure(date: planningDays.keys[indexPath.section])
            }

            let weekHeaderRegistration = UICollectionView.SupplementaryRegistration<PlanningWeekHeaderView>(
                elementKind: PlanningLayoutMetrics.weekHeaderKind
            ) { [weak self] headerView, _, indexPath in
                guard let self, indexPath.section < planningDays.count else { return }
                headerView.configure(date: planningDays.keys[indexPath.section])
            }

            datasource = UICollectionViewDiffableDataSource<Date, PlanningItemId>(
                collectionView: collectionView
            ) { collectionView, indexPath, itemId in
                switch itemId {
                case .empty:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: emptyCellRegistration,
                        for: indexPath,
                        item: .empty
                    )
                case .event:
                    guard let day = self.planningDays[self.planningDays.keys[indexPath.section]] else {
                        return nil
                    }
                    let event = day.events[indexPath.item]

                    let registration = event.isAllDay ? allDayCellRegistration : eventCellRegistration
                    return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: event)
                }
            }

            datasource?.supplementaryViewProvider = { collectionView, elementKind, indexPath in
                switch elementKind {
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
        }

        func applySnapshot(animated: Bool) {
            var snapshot = NSDiffableDataSourceSnapshot<Date, PlanningItemId>()
            for (dayDate, planningDay) in planningViewModel.planningDays {
                snapshot.appendSections([dayDate])
                if planningDay.events.isEmpty {
                    snapshot.appendItems([.empty(dayDate)], toSection: dayDate)
                } else {
                    snapshot.appendItems(planningDay.events.map { .event(id: $0.id) }, toSection: dayDate)
                }
            }
            datasource?.apply(snapshot, animatingDifferences: animated)
        }

        func scrollToStartOfDay(date: Date, animated: Bool, for collectionView: UICollectionView) {
            let startOfDayDate = Calendar.current.startOfDay(for: date)
            guard let sectionIndex = planningDays.index(forKey: startOfDayDate) else {
                return
            }

            let indexPath = IndexPath(item: 0, section: sectionIndex)
            collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
        }
    }
}

#Preview {
    PlanningCollectionView(planningViewModel: PlanningViewModel())
        .ignoresSafeArea()
}
