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
import Foundation
import Observation

@Observable
public final class SettingsStore {
    public var theme: Theme {
        didSet { UserDefaults.standard.theme = theme }
    }

    public var startDay: StartDay {
        didSet { UserDefaults.standard.startDay = startDay }
    }

    public var isShowWeekends: Bool {
        didSet { UserDefaults.standard.isShowWeekends = isShowWeekends }
    }

    public var defaultEventDuration: DefaultEventDuration {
        didSet { UserDefaults.standard.defaultEventDuration = defaultEventDuration }
    }

    public init() {
        theme = UserDefaults.standard.theme
        startDay = UserDefaults.standard.startDay
        isShowWeekends = UserDefaults.standard.isShowWeekends
        defaultEventDuration = UserDefaults.standard.defaultEventDuration
    }
}
