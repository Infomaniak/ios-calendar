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
import InfomaniakCore
import InfomaniakCoreSwiftUI
import NukeUI
import SwiftUI

public struct AvatarView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts: [CalendarAccount.ID: CalendarAccount]

    let avatar: UIAvatarType?
    let displayName: String
    let email: String

    public init(avatar: UIAvatarType?, displayName: String, email: String) {
        self.avatar = avatar
        self.displayName = displayName
        self.email = email
    }

    public var body: some View {
        if let avatarRequest = avatar?.imageRequest(accounts: calendarAccounts) {
            LazyImage(request: avatarRequest) { state in
                if let image = state.image {
                    AvatarImage(image: image)
                } else {
                    initialsView
                }
            }
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        InitialsView(
            initials: NameFormatter(fullName: displayName).initials,
            backgroundColor: Color.backgroundColor(from: email.hash),
            foregroundColor: Color.white
        )
    }
}
