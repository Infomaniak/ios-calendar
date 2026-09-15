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

public struct TimeZoneDisplayNameFormatStyle: FormatStyle, Sendable {
    private let locale: Locale

    public init(locale: Locale = .autoupdatingCurrent) {
        self.locale = locale
    }

    public func format(_ timeZone: TimeZone) -> String {
        let city = timeZone.identifier
            .split(separator: "/")
            .last
            .map(String.init)?
            .replacingOccurrences(of: "_", with: " ") ?? timeZone.identifier
        let displayName = timeZone.localizedName(for: .generic, locale: locale) ?? timeZone.identifier

        return "\(city) - \(displayName)"
    }
}

public extension FormatStyle where Self == TimeZoneDisplayNameFormatStyle {
    static var timeZoneDisplayName: TimeZoneDisplayNameFormatStyle {
        TimeZoneDisplayNameFormatStyle()
    }

    static func timeZoneDisplayName(locale: Locale) -> TimeZoneDisplayNameFormatStyle {
        TimeZoneDisplayNameFormatStyle(locale: locale)
    }
}

public extension TimeZone {
    func formatted<Style: FormatStyle>(_ style: Style) -> Style.FormatOutput where Style.FormatInput == TimeZone {
        style.format(self)
    }
}
