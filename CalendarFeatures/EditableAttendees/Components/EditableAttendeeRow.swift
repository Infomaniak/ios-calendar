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
import DesignSystem
import ESDSFoundation
import ESDSSymbols
import SwiftUI

enum AttendeeAddedState {
    case notAdded
    case sameEmail
    case sameAttendee
}

struct EditableAttendeeRow: View {
    @Environment(\.esdsTheme) private var theme

    let attendee: UIAttendee

    let addedState: AttendeeAddedState
    let action: (() -> Void)?

    private var isSelectable: Bool {
        action != nil && addedState == .notAdded
    }

    private var isSameAttendee: Bool {
        addedState == .sameAttendee
    }

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: IKPadding.micro) {
                ParticipantCellView(
                    avatar: attendee.contact?.avatar,
                    displayName: attendee.displayName ?? attendee.email,
                    email: attendee.email,
                    isOrganizer: isSameAttendee && attendee.isOrganizer,
                    status: isSameAttendee ? attendee.status : nil
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                if addedState != .notAdded && action != nil {
                    ESDSSymbols.check.image
                        .font(.system(size: 24))
                        .foregroundStyle(theme.color.contentSecondary)
                        .accessibilityHidden(true)
                }
            }
        }
        .allowsHitTesting(isSelectable)
        .accessibilityAddTraits(addedState != .notAdded ? .isSelected : [])
    }
}

#Preview {
    List {
        EditableAttendeeRow(attendee: .preview, addedState: .notAdded) {}
        EditableAttendeeRow(attendee: .preview, addedState: .sameEmail) {}
        EditableAttendeeRow(attendee: .preview, addedState: .sameAttendee) {}
        EditableAttendeeRow(attendee: .preview, addedState: .sameAttendee, action: nil)
    }
}
