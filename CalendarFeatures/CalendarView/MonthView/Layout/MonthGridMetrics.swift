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

enum MonthGridSizing: Equatable {
    case fill
    case square

    init(containerSize: CGSize) {
        self = containerSize.width > containerSize.height ? .square : .fill
    }
}

struct MonthGridMetrics: Equatable {
    static let columnCount = 7

    static let laneSpacing: CGFloat = 2
    static let hiddenEventsIndicatorHeight: CGFloat = 12
    static let separatorThickness: CGFloat = 1

    let containerSize: CGSize
    let weekNumberWidth: CGFloat
    let dayNumberHeight: CGFloat
    let laneHeight: CGFloat

    var sizing: MonthGridSizing {
        MonthGridSizing(containerSize: containerSize)
    }

    var columnWidth: CGFloat {
        max(containerSize.width - weekNumberWidth, 0) / CGFloat(Self.columnCount)
    }

    var totalDayNumberHeight: CGFloat {
        return dayNumberHeight + 8 * 2 + 4 * 2
    }

    func rowHeight(weekCount: Int) -> CGFloat {
        let fillingRowHeight = containerSize.height / CGFloat(max(weekCount, 1))
        switch sizing {
        case .fill:
            return fillingRowHeight
        case .square:
            return max(columnWidth, fillingRowHeight)
        }
    }

    func maxEventsCount(rowHeight: CGFloat) -> Int {
        let availableHeight = rowHeight - totalDayNumberHeight - Self.laneSpacing
        guard availableHeight > 0 else {
            return 0
        }

        return Int((availableHeight + Self.laneSpacing) / (laneHeight + Self.laneSpacing))
    }

    func maxEventsCountWithHiddenEventsIndicator(rowHeight: CGFloat) -> Int {
        let availableHeight = rowHeight - totalDayNumberHeight - Self.laneSpacing - Self.hiddenEventsIndicatorHeight
        guard availableHeight > 0 else {
            return 0
        }

        return Int(availableHeight / (laneHeight + Self.laneSpacing))
    }
}
