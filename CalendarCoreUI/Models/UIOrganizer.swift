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

public struct UIOrganizer: UICalendarUser, Sendable, Equatable, Hashable {
    public let email: String
    public let displayName: String?
    public let contact: UIContact?
}

public extension UIOrganizer {
    init(organizer: Organizer) {
        email = organizer.email
        displayName = organizer.displayName
        if let contact = organizer.contact {
            self.contact = UIContact(contact: contact)
        } else {
            contact = nil
        }
    }
}
