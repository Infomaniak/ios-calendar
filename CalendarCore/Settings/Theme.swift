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
import SwiftUI

public enum Theme: String, CaseIterable, SettingsOptionEnum, Sendable {
    case light
    case dark
    case system

    public var interfaceStyle: UIUserInterfaceStyle {
        let styles: [Theme: UIUserInterfaceStyle] = [
            .light: .light,
            .dark: .dark,
            .system: .unspecified
        ]
        return styles[self] ?? .unspecified
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    public var title: String {
        switch self {
        case .light:
            return "Clair"
        case .dark:
            return "Sombre"
        case .system:
            return "Système"
        }
    }

    public var image: Image? {
        switch self {
        case .light:
            return Image(systemName: "sun.max")
        case .dark:
            return Image(systemName: "moon.fill")
        case .system:
            return Image(systemName: "iphone.gen3.sizes")
        }
    }

    public var hint: String? {
        return nil
    }
}
