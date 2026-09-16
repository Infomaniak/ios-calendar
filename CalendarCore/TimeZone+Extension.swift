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

public extension TimeZone {
    var formattedIdentifier: String {
        let components = identifier.split(separator: "/")
        guard let region = components.first,
              let location = components.last,
              region != location else {
            return identifier.replacingOccurrences(of: "_", with: " ")
        }

        let formattedLocation = location.replacingOccurrences(of: "_", with: " ")
        let formattedRegion = region.replacingOccurrences(of: "_", with: " ")
        return "\(formattedLocation), \(formattedRegion)"
    }

    func utcOffset(at date: Date) -> String {
        let offsetInMinutes = secondsFromGMT(for: date) / 60

        let sign = offsetInMinutes >= 0 ? "+" : "-"
        let absoluteOffset = abs(offsetInMinutes)
        let hours = absoluteOffset / 60
        let minutes = absoluteOffset % 60

        guard minutes != 0 else {
            return "UTC\(sign)\(hours)"
        }

        return String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }
}
