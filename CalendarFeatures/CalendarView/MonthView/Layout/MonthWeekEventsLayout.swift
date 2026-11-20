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

struct MonthEventPlacement: LayoutValueKey {
    static let defaultValue = MonthEventPlacement(column: 0, span: 1, lane: 0, height: nil)

    let column: Int
    let span: Int
    let lane: Int
    /// Overrides the lane height, the subview stays positioned at the top of its lane.
    let height: CGFloat?
}

extension View {
    func monthEventPlacement(column: Int, span: Int = 1, lane: Int, height: CGFloat? = nil) -> some View {
        layoutValue(
            key: MonthEventPlacement.self,
            value: MonthEventPlacement(column: column, span: span, lane: lane, height: height)
        )
    }
}

struct MonthWeekEventsLayout: Layout {
    let columnCount: Int
    let laneHeight: CGFloat
    let laneSpacing: CGFloat
    let horizontalInset: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = subviews.map { subview in
            let placement = subview[MonthEventPlacement.self]
            return laneOffset(placement.lane) + (placement.height ?? laneHeight)
        }.max() ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard columnCount > 0 else {
            return
        }

        let columnWidth = bounds.width / CGFloat(columnCount)
        for subview in subviews {
            let placement = subview[MonthEventPlacement.self]
            let width = max(CGFloat(placement.span) * columnWidth - horizontalInset * 2, 0)
            subview.place(
                at: CGPoint(
                    x: bounds.minX + CGFloat(placement.column) * columnWidth + horizontalInset,
                    y: bounds.minY + laneOffset(placement.lane)
                ),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: width, height: placement.height ?? laneHeight)
            )
        }
    }

    private func laneOffset(_ lane: Int) -> CGFloat {
        CGFloat(lane) * (laneHeight + laneSpacing)
    }
}
