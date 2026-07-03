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

import DifferenceKit
import Foundation

/// Snapshot of the planning collection view: one `ArraySection` per day, each
/// holding the rows (`PlanningItem`) to display for that day.
typealias PlanningViewDifference = [ArraySection<PlanningDay, PlanningItem>]

extension PlanningDay: Differentiable {
    /// A day is uniquely identified by its date, so shifting the window only ever
    /// produces section inserts/deletes at the edges (never spurious reloads).
    var differenceIdentifier: Date {
        date
    }

    /// Section-level content only tracks whether the day has a header. Event changes
    /// are diffed through the section's elements, keeping row-level animations intact.
    func isContentEqual(to source: PlanningDay) -> Bool {
        events.isEmpty == source.events.isEmpty && isWeekStart == source.isWeekStart
    }
}
