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

public struct UIContact: Sendable, Equatable, Hashable, Identifiable {
    public var id: String {
        return "\(email)-\(name)"
    }

    public let email: String
    public let name: String
    public let avatar: UIAvatarType?
    public let comesFromApi: Bool
}

public extension UIContact {
    init(contact: Contact) {
        email = contact.email
        name = contact.name
        comesFromApi = contact.comesFromApi
        if let avatar = contact.avatar {
            self.avatar = UIAvatarType(avatar: avatar)
        } else {
            avatar = nil
        }
    }

    var sdkValue: Contact {
        let sdkAvatar: (any ContactAvatar)?
        switch avatar {
        case .remote(let rawURL, let accountId):
            sdkAvatar = ContactAvatarRemote(url: rawURL, accountId: accountId)
        case .device(let contactId):
            sdkAvatar = ContactAvatarDevice(id: contactId)
        case .user, nil:
            sdkAvatar = nil
        }

        return Contact(email: email, name: name, avatar: sdkAvatar, comesFromApi: comesFromApi)
    }
}
