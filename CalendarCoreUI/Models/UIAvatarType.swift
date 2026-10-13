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

import CalendarCore
import Foundation
import MultiplatformCalendar
import Nuke

public enum UIAvatarType: Sendable, Equatable, Hashable {
    case remote(rawURL: String, accountId: Int64)
    case user(rawURL: String?)

    func imageRequest(accounts: [CalendarAccount.ID: CalendarAccount]) -> ImageRequest? {
        switch self {
        case .remote(let rawURL, let accountId):
            guard let url = URL(string: rawURL),
                  let accessToken = accounts[Int(accountId)]?.token.accessToken,
                  !accessToken.isEmpty else { return nil }

            var authenticatedUrlRequest = URLRequest(url: url)
            authenticatedUrlRequest.addValue(
                "Bearer \(accessToken)",
                forHTTPHeaderField: "Authorization"
            )

            return ImageRequest(urlRequest: authenticatedUrlRequest)
        case .user(let rawURL):
            guard let rawURL,
                  let url = URL(string: rawURL) else { return nil }

            return ImageRequest(url: url)
        }
    }
}

public extension UIAvatarType {
    init(avatar: any ContactAvatar) {
        switch onEnum(of: avatar) {
        case .remote(let remote):
            self = .remote(rawURL: remote.url, accountId: remote.accountIdValue)
        }
    }
}
