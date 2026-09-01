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

import CalendarResources
import ESDSFoundation
import Foundation
import InfomaniakCoreUIResources
import MultiplatformCalendar
import SwiftUI

public enum UIParticipationStatus: String, Sendable, CaseIterable {
    case accepted
    case tentative
    case needsAction
    case declined
}

public extension UIParticipationStatus {
    init(participationStatus: MultiplatformCalendar.ParticipationStatus) {
        switch participationStatus {
        case .accepted:
            self = .accepted
        case .declined:
            self = .declined
        case .tentative:
            self = .tentative
        case .needsAction:
            self = .needsAction
        }
    }

    var name: String {
        switch self {
        case .accepted:
            return CalendarResourcesStrings.statusAcceptedLabel
        case .tentative:
            return InfomaniakCoreUIResources.CoreUILocalizable.buttonMaybe
        case .needsAction:
            return CalendarResourcesStrings.statusNeedsActionLabel
        case .declined:
            return CalendarResourcesStrings.statusDeclinedLabel
        }
    }

    func color(theme: ESDSTheme) -> Color {
        switch self {
        case .accepted:
            return theme.color.backgroundFeedbackSuccessDim1Default
        case .tentative:
            return theme.color.contentDisabled
        case .needsAction:
            return theme.color.backgroundFeedbackWarningDim1Default
        case .declined:
            return theme.color.backgroundFeedbackErrorDim1Default
        }
    }

    var sortOrder: Int {
        switch self {
        case .accepted:
            return 0
        case .tentative:
            return 1
        case .needsAction:
            return 2
        case .declined:
            return 3
        }
    }
}

public struct UIAttendee: Sendable, Equatable, Hashable, Identifiable {
    public var id: String {
        return email
    }

    public let displayName: String?
    public let email: String
    public let status: UIParticipationStatus
    public let isOrganizer: Bool

    public init(displayName: String?, email: String, status: UIParticipationStatus, isOrganizer: Bool = false) {
        self.displayName = displayName
        self.email = email
        self.status = status
        self.isOrganizer = isOrganizer
    }
}

public extension UIAttendee {
    init(attendee: MultiplatformCalendar.Attendee) {
        displayName = attendee.displayName
        email = attendee.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        status = UIParticipationStatus(participationStatus: attendee.status)
        isOrganizer = attendee.isOrganizer
    }
}

public extension UIAttendee {
    static let preview = UIAttendee(displayName: "Tim Cook", email: "tim@apple.com", status: .accepted)
    static let previews = [
        UIAttendee.preview, UIAttendee(displayName: "John Ternus", email: "john@apple.com", status: .declined)
    ]
}
