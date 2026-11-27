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

import CalendarCore
import CalendarResources
import Foundation

public extension EventRecurrence {
    var label: String {
        switch self {
        case .none:
            return CalendarResourcesStrings.recurrenceNone
        case .daily:
            return CalendarResourcesStrings.recurrenceEveryDay
        case .weekly:
            return CalendarResourcesStrings.recurrenceEveryWeek
        case .monthly:
            return CalendarResourcesStrings.recurrenceEveryMonth
        case .yearly:
            return CalendarResourcesStrings.recurrenceEveryYear
        case .custom:
            return CalendarResourcesStrings.recurrenceCustom
        }
    }
}
