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

public enum UIParticipationStatus: String, Sendable {
    case accepted
    case declined
    case tentative
    case needsAction
}

public extension UIParticipationStatus {
    init(participationStatus: MultiplatformCalendar.ParticipationStatus) {
        switch participationStatus {
        case .accepted: self = .accepted
        case .declined: self = .declined
        case .tentative: self = .tentative
        case .needsAction: self = .needsAction
        }
    }
}

public struct UIAttendee: Sendable, Equatable, Hashable {
    public let displayName: String?
    public let email: String
    public let status: UIParticipationStatus

    public init(displayName: String?, email: String, status: UIParticipationStatus) {
        self.displayName = displayName
        self.email = email
        self.status = status
    }
}

public extension UIAttendee {
    init(attendee: MultiplatformCalendar.Attendee) {
        displayName = attendee.displayName
        email = attendee.email
        status = UIParticipationStatus(participationStatus: attendee.status)
    }
}

public extension UIAttendee {
    static let preview = UIAttendee(displayName: "Tim Cook", email: "tim@apple.com", status: .accepted)
    static let previews = [
        UIAttendee.preview, UIAttendee(displayName: "John Ternus", email: "john@apple.com", status: .declined)
    ]
}
