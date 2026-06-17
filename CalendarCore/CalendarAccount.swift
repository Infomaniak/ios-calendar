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
import InfomaniakCore
import InfomaniakLogin
import KmpCalendar

public struct CalendarAccount: Identifiable, Equatable, Hashable, Sendable {
    public var id: Int {
        token.userId
    }

    public let token: ApiToken
    public let user: UserProfile
    private let davUsername: String
    private let davPassword: String

    public var davCredentials: DavCredentials {
        DavCredentials(username: davUsername, password: davPassword)
    }

    public init(token: ApiToken, user: UserProfile, davCredentials: DavCredentials) {
        self.token = token
        self.user = user
        davUsername = davCredentials.username
        davPassword = davCredentials.password
    }
}
