//
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

struct DayViewLayout: Layout {
    let verticalInset: CGFloat
    let leadingInset: CGFloat

    let pointsPerHour: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        return CGSize(width: proposal.width ?? 100, height: proposal.height ?? 100)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            let tag = subview.containerValues.tag(for: Date.self) ?? .now

            let hour = Calendar.current.component(.hour, from: tag)
            let minutes = Calendar.current.component(.minute, from: tag)

            let offsetY = (CGFloat(hour) + CGFloat(minutes) / 60) * pointsPerHour + verticalInset

            let preferredSize = subview.sizeThatFits(.unspecified)
            subview.place(at: CGPoint(x: leadingInset, y: offsetY), proposal: .init(width: proposal.width, height: preferredSize.height))
        }
    }
}
