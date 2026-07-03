//
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
import SwiftUI

extension AvatarView {
    init(attendee: UIAttendee, size: CGFloat) {
        self.init(
            rawAvatarURL: nil,
            displayName: attendee.displayName ?? attendee.email,
            email: attendee.email,
            size: size
        )
    }
}

struct NextEventCardAvatarStackView: View {
    static let height: CGFloat = 24
    static let maxAttendees = 3

    let attendees: [UIAttendee]
    let progression: Double

    private var visibleAttendees: [UIAttendee] {
        return Array(attendees.prefix(Self.maxAttendees))
    }

    private var hiddenAttendeesCount: Int {
        return max(0, attendees.count - Self.maxAttendees)
    }

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: -Self.height / 3) {
                ForEach(Array(visibleAttendees.enumerated()), id: \.element) { attendee in
                    AvatarView(attendee: attendee.element, size: Self.height)
                        .offset(x: Self.height * 2/3 * CGFloat(attendee.offset) * CGFloat(1 - progression) * -1)
                }
            }
            .compositingGroup()

            if hiddenAttendeesCount > 0 {
                Text("+\(hiddenAttendeesCount) participants")
            }
        }
    }
}

#Preview {
    NextEventCardAvatarStackView(attendees: UIAttendee.previews, progression: 1)
    NextEventCardAvatarStackView(attendees: Array(repeating: UIAttendee.preview, count: 10), progression: 1)
}
