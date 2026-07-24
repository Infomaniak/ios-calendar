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
import Foundation
import UIKit

struct PlanningCellSizeHelper {
    private let dateHeight = UIFont.preferredFont(forTextStyle: .caption2).lineHeight
    private let titleHeight = UIFont.preferredFont(forTextStyle: .caption1).lineHeight

    func heightForCell(event: CalendarCoreUI.UIEvent) -> CGFloat {
        if event.isAllDay {
            return titleHeight + dateHeight
        } else {
            return titleHeight + dateHeight + EventIconsView.iconSize + event.additionalDurationHeight
        }
    }
}
