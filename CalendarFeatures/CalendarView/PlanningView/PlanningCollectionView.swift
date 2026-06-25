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
    static let dayHeaderHeight: CGFloat = 64
    static let weekHeaderHeight: CGFloat = 32

    static let dayHeaderKind = "PlanningDayHeaderKind"
    static let weekHeaderKind = "PlanningWeekHeaderKind"
}

struct PlanningCollectionView: UIViewRepresentable {
    let planningDays: [PlanningDay]

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
        context.coordinator.updateData(planningDays: planningDays)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject, UICollectionViewDelegate {
        private var datasource: UICollectionViewDiffableDataSource<Date, CalendarCoreUI.UIEvent>?

        private var planningDays: [PlanningDay] = []

        // MARK: - Layout

        func makeLayout() -> UICollectionViewCompositionalLayout {
            let configuration = UICollectionViewCompositionalLayoutConfiguration()
            configuration.interSectionSpacing = IKPadding.mini

            return UICollectionViewCompositionalLayout(
                sectionProvider: { [weak self] sectionIndex, _ in
                    let showsWeekHeader = self?.shouldShowWeekHeader(at: sectionIndex) ?? false
                    return Coordinator.makeDaySection(showsWeekHeader: showsWeekHeader)
                },
                configuration: configuration
            )
        }

        private func shouldShowWeekHeader(at sectionIndex: Int) -> Bool {
            guard sectionIndex < planningDays.count else { return false }
            guard sectionIndex > 0 else { return true }

            let currentDate = planningDays[sectionIndex].date
            let previousDate = planningDays[sectionIndex - 1].date
            return !Calendar.current.isDate(currentDate, equalTo: previousDate, toGranularity: .weekOfYear)
        }

        private static func makeDaySection(showsWeekHeader: Bool) -> NSCollectionLayoutSection {
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(PlanningLayoutMetrics.eventRowHeight)
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
                trailing: IKPadding.mini
            )

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
                section.boundarySupplementaryItems = [weekHeader, dayHeader]
            } else {
                section.boundarySupplementaryItems = [dayHeader]
            }

            return section
        }

        // MARK: - Data source

        func setupDatasource(for collectionView: UICollectionView) {
            let cellRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell, CalendarCoreUI.UIEvent
            > { cell, _, event in
                if event.isAllDay {
                    cell.contentConfiguration = UIHostingConfiguration {
                        PlanningDayEventView(event: event)
                    }
                    .margins(.all, 0)
                    .minSize(height: 20)
                } else {
                    cell.contentConfiguration = UIHostingConfiguration {
                        PlanningEventView(event: event)
                    }
                    .margins(.all, 0)
                    .minSize(height: 20)
                }
            }

            let dayHeaderRegistration = UICollectionView.SupplementaryRegistration<PlanningDayHeaderView>(
                elementKind: PlanningLayoutMetrics.dayHeaderKind
            ) { [weak self] headerView, _, indexPath in
                guard let self, indexPath.section < planningDays.count else { return }
                headerView.configure(date: planningDays[indexPath.section].date)
            }

            let weekHeaderRegistration = UICollectionView.SupplementaryRegistration<PlanningWeekHeaderView>(
                elementKind: PlanningLayoutMetrics.weekHeaderKind
            ) { [weak self] headerView, _, indexPath in
                guard let self, indexPath.section < planningDays.count else { return }
                headerView.configure(date: planningDays[indexPath.section].date)
            }

            datasource = UICollectionViewDiffableDataSource<Date, CalendarCoreUI.UIEvent>(
                collectionView: collectionView
            ) { collectionView, indexPath, event in
                collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: event)
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

        func updateData(planningDays: [PlanningDay]) {
            guard self.planningDays != planningDays else { return }
            self.planningDays = planningDays
            var snapshot = NSDiffableDataSourceSnapshot<Date, CalendarCoreUI.UIEvent>()
            for day in planningDays {
                snapshot.appendSections([day.date])
                snapshot.appendItems(day.events, toSection: day.date)
            }
            datasource?.apply(snapshot, animatingDifferences: true)
        }
    }
}

#Preview {
    PlanningCollectionView(planningDays: PlanningDay.preview)
        .ignoresSafeArea()
}
