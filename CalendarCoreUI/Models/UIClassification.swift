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

import CalendarResources
import Foundation
import MultiplatformCalendar
import SwiftUI

public enum UIClassification: String, Sendable, CaseIterable {
    case `public`
    case `private`
    case confidential
    case custom

    public var text: String? {
        switch self {
        case .public:
            return CalendarResourcesStrings.publicLabel
        case .private:
            return CalendarResourcesStrings.privateLabel
        default:
            return nil
        }
    }

    public var icon: Image? {
        switch self {
        case .public:
            return CalendarResourcesAsset.Images.lockOpen.swiftUIImage
        case .private:
            return CalendarResourcesAsset.Images.lock.swiftUIImage
        default:
            return nil
        }
    }
}

public extension UIClassification {
    init?(classification: MultiplatformCalendar.Classification?) {
        guard let classification else {
            self = .public
            return nil
        }
        switch onEnum(of: classification) {
        case .public: self = .public
        case .private: self = .private
        case .confidential: self = .confidential
        case .custom: self = .custom
        }
    }
}
