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

import MultiplatformCalendar

public struct UICalendarSection: Identifiable, Equatable, Sendable {
    public var id: String {
        "\(accountId)-\(organisationId.map { String($0) } ?? "none")"
    }

    public let accountId: Int
    public let organisationId: Int?
    public var organisationName: String?
    public let calendars: [UICalendar]

    public init(section: CalendarSection) {
        accountId = Int(section.accountIdValue)
        if let organisation = section.organisation {
            organisationId = Int(organisation.idValue)
            organisationName = organisation.name
        } else {
            organisationId = nil
            organisationName = nil
        }
        calendars = section.calendars.map { UICalendar(calendar: $0) }
    }

    public init(accountId: Int, organisationId: Int?, organisationName: String?, calendars: [UICalendar]) {
        self.accountId = accountId
        self.organisationId = organisationId
        self.organisationName = organisationName
        self.calendars = calendars
    }
}

public extension UICalendarSection {
    static let preview = UICalendarSection(
        accountId: 1,
        organisationId: 2,
        organisationName: "Infomaniak Group",
        calendars: [UICalendar.preview]
    )
}
