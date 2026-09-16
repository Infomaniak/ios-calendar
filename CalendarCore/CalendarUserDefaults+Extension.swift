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
    static let firstWeekday = UserDefaults.Keys(rawValue: "firstWeekday")
    static let displayWeekends = UserDefaults.Keys(rawValue: "displayWeekends")
    static let defaultEventDuration = UserDefaults.Keys(rawValue: "defaultEventDuration")
    static let customTimeZoneIdentifier = UserDefaults.Keys(rawValue: "customTimeZoneIdentifier")
}

public extension UserDefaults {
    nonisolated(unsafe) static let shared = UserDefaults(suiteName: "group.\(CalendarTargetAssembly.bundleId)")!

    var theme: Theme {
        get {
            if object(forKey: key(.theme)) == nil {
                set(DefaultPreferences.theme.rawValue, forKey: key(.theme))
            }
            return Theme(rawValue: string(forKey: key(.theme)) ?? "") ?? DefaultPreferences.theme
        }
        set {
            setValue(newValue.rawValue, forKey: key(.theme))
        }
    }

    var firstWeekday: Int {
        get {
            if object(forKey: key(.firstWeekday)) == nil {
                set(DefaultPreferences.firstWeekday, forKey: key(.firstWeekday))
            }
            return integer(forKey: key(.firstWeekday))
        }
        set {
            setValue(newValue, forKey: key(.firstWeekday))
        }
    }

    var displayWeekends: Bool {
        get {
            if object(forKey: key(.displayWeekends)) == nil {
                set(DefaultPreferences.displayWeekends, forKey: key(.displayWeekends))
            }
            return bool(forKey: key(.displayWeekends))
        }
        set {
            set(newValue, forKey: key(.displayWeekends))
        }
    }

    var defaultEventDuration: DefaultEventDuration {
        get {
            let rawValue = integer(forKey: key(.defaultEventDuration))
            return rawValue == 0 ? DefaultPreferences.defaultEventDuration : DefaultEventDuration(rawValue: rawValue)
        }
        set {
            setValue(newValue.rawValue, forKey: key(.defaultEventDuration))
        }
    }

    var timeZoneIdentifier: String? {
        get {
            return string(forKey: key(.customTimeZoneIdentifier))
        }
        set {
            set(newValue, forKey: key(.customTimeZoneIdentifier))
        }
    }
}
