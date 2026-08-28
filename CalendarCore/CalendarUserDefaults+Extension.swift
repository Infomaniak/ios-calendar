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

import Foundation
import InfomaniakCore
import SwiftUI

public protocol SettingsOptionEnum {
    var title: String { get }
    var image: Image? { get }
    var hint: String? { get }
}

public extension UserDefaults.Keys {
    static let theme = UserDefaults.Keys(rawValue: "theme")
    static let startDay = UserDefaults.Keys(rawValue: "startDay")
    static let isShowWeekends = UserDefaults.Keys(rawValue: "isShowWeekends")
    static let defaultEventDuration = UserDefaults.Keys(rawValue: "defaultEventDuration")
}

public extension UserDefaults {
    var theme: Theme {
        get {
            return Theme(rawValue: string(forKey: key(.theme)) ?? "") ?? DefaultPreferences.theme
        }
        set {
            setValue(newValue.rawValue, forKey: key(.theme))
        }
    }

    var startDay: StartDay {
        get {
            return StartDay(rawValue: string(forKey: key(.startDay)) ?? "") ?? DefaultPreferences.startDay
        }
        set {
            setValue(newValue.rawValue, forKey: key(.startDay))
        }
    }

    var isShowWeekends: Bool {
        get {
            if object(forKey: key(.isShowWeekends)) == nil {
                set(DefaultPreferences.isShowWeekends, forKey: key(.isShowWeekends))
            }
            return bool(forKey: key(.isShowWeekends))
        }
        set {
            set(newValue, forKey: key(.isShowWeekends))
        }
    }

    var defaultEventDuration: DefaultEventDuration {
        get {
            let minutes = integer(forKey: key(.defaultEventDuration))
            return minutes == 0 ? DefaultPreferences.defaultEventDuration : DefaultEventDuration(minutes: minutes)
        }
        set {
            setValue(newValue.minutes, forKey: key(.defaultEventDuration))
        }
    }
}
