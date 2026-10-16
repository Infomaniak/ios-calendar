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

import DesignSystem
import Foundation

struct AllDayEventsListMetrics {
    static let maxVisibleRows = 2

    let eventTitleLineHeight: CGFloat

    func isScrollable(rowCount: Int) -> Bool {
        return rowCount > Self.maxVisibleRows
    }

    func listHeight(rowCount: Int) -> CGFloat {
        let rowHeight = eventTitleLineHeight + IKPadding.mini * 2
        let visibleRowCount = CGFloat(min(rowCount, Self.maxVisibleRows))
        let rowsHeight = visibleRowCount * rowHeight + (visibleRowCount - 1) * IKPadding.micro
        let peekHeight = isScrollable(rowCount: rowCount) ? IKPadding.micro + IKPadding.mini : 0
        return rowsHeight + peekHeight
    }
}
