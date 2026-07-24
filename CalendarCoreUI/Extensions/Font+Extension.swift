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

import SwiftUI
import UIKit

// MARK: - Emphasized weight

public extension Font.Weight {
    static let emphasized = Font.Weight.semibold
}

public extension UIFont.Weight {
    static let emphasized = UIFont.Weight.semibold
}

// MARK: - Utils

public extension UIFont {
    static func scaledFontSize(
        _ textStyle: UIFont.TextStyle,
        size: CGFloat,
        weight: UIFont.Weight = .regular
    ) -> CGFloat {
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let font = metrics.scaledFont(for: .systemFont(ofSize: size, weight: weight))
        return font.pointSize
    }
}
