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

import CalendarCoreUI
import InfomaniakCore
import InfomaniakCoreSwiftUI
import SwiftUI

struct AccountCellView: View {
    let rawAvatarURL: String?
    let displayName: String
    let email: String
    let avatarSize: CGFloat = 40

    var body: some View {
        HStack {
            AvatarView(rawAvatarURL: rawAvatarURL, displayName: displayName,
                       email: email, size: avatarSize)

            VStack(alignment: .leading, spacing: 0) {
                Text(displayName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(email)
                    .font(.body)
                    .foregroundStyle(.gray)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
