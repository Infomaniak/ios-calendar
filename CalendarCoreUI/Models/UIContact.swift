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
import MultiplatformCalendar

public enum UIContactAvatar: Sendable, Equatable, Hashable {
    case remote(url: String, accountId: Int64)

    public init(avatar: any ContactAvatar) {
        switch onEnum(of: avatar) {
        case .remote(let remote):
            self = .remote(url: remote.url, accountId: remote.accountIdValue)
        }
    }
}

public struct UIContact: Sendable, Equatable, Hashable {
    public let email: String
    public let name: String
    public let avatar: UIContactAvatar?
    public let comesFromApi: Bool

    public init(contact: Contact) {
        email = contact.email
        name = contact.name
        avatar = contact.avatar.map { UIContactAvatar(avatar: $0) }
        comesFromApi = contact.comesFromApi
    }
}

public struct UIOrganizer: Sendable, Equatable, Hashable {
    public let email: String
    public let displayName: String?
    public let contact: UIContact?

    public init(organizer: Organizer) {
        email = organizer.email
        displayName = organizer.displayName
        contact = organizer.contact.map { UIContact(contact: $0) }
    }
}
