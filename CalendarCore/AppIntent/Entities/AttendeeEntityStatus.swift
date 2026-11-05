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

import AppIntents
import MultiplatformCalendar

@available(iOS 27.0, *)
@AppEnum(schema: .calendar.attendeeStatus)
public enum AttendeeEntityStatus: String, Sendable {
    case accepted
    case declined
    case tentative

    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .accepted: DisplayRepresentation(title: "statusAcceptedLabel"),
        .declined: DisplayRepresentation(title: "statusDeclinedLabel"),
        .tentative: DisplayRepresentation(title: "statusTentativeLabel")
    ]
}

@available(iOS 27.0, *)
public extension AttendeeEntityStatus {
    init?(participationStatus: ParticipationStatus) {
        switch participationStatus {
        case .accepted:
            self = .accepted
        case .declined:
            self = .declined
        case .tentative:
            self = .tentative
        case .needsAction, .delegated:
            return nil
        }
    }
}
