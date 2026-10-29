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
import ESDSSymbols
import SwiftUI

struct SearchResultRow: View {
    let attendee: UIAttendee
    let alreadyExist: Bool
    let equalAttendeeAlreadyExist: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: IKPadding.micro) {
                ParticipantCellView(
                    avatar: attendee.contact?.avatar,
                    displayName: attendee.displayName ?? attendee.email,
                    email: attendee.email,
                    isOrganizer: equalAttendeeAlreadyExist && attendee.isOrganizer,
                    status: equalAttendeeAlreadyExist ? attendee.status : nil
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                if alreadyExist {
                    ESDSSymbols.check.image
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(alreadyExist)
        .accessibilityAddTraits(.isSelected)
    }
}

#Preview {
    SearchResultRow(attendee: .preview, alreadyExist: false, equalAttendeeAlreadyExist: false) {}
    SearchResultRow(attendee: .preview, alreadyExist: true, equalAttendeeAlreadyExist: false) {}
    SearchResultRow(attendee: .preview, alreadyExist: true, equalAttendeeAlreadyExist: true) {}
}
