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
import SwiftUI

public enum LinkType {
    case pdf, jpg, json, zip, xlsx

    init?(url: URL) {
        switch url.pathExtension.lowercased() {
        case "pdf": self = .pdf
        case "jpg", "jpeg": self = .jpg
        case "json": self = .json
        case "zip": self = .zip
        case "xlsx", "xls": self = .xlsx
        default: return nil
        }
    }

    public var icon: Image {
        switch self {
        case .pdf:
            return CalendarResourcesAsset.Images.fileText.swiftUIImage
        case .jpg:
            return CalendarResourcesAsset.Images.fileSunMountain.swiftUIImage
        case .json:
            return CalendarResourcesAsset.Images.fileBraces.swiftUIImage
        case .zip:
            return CalendarResourcesAsset.Images.fileZipper.swiftUIImage
        case .xlsx:
            return CalendarResourcesAsset.Images.fileChart.swiftUIImage
        }
    }
}
