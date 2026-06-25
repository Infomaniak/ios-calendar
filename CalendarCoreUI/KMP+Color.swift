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

extension Color {
    init(argb: Int32) {
        let value = UInt32(bitPattern: argb)

        let a = Double((value >> 24) & 0xFF) / 255.0
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    var argb: Int32 {
        let components = cgColor?.components ?? [0, 0, 0, 0]
        let r = UInt32(components[0] * 255.0) << 16
        let g = UInt32(components[1] * 255.0) << 8
        let b = UInt32(components[2] * 255.0)
        let a = UInt32((cgColor?.alpha ?? 1.0) * 255.0) << 24

        return Int32(bitPattern: a | r | g | b)
    }
}
