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
@AppEnum(schema: .calendar.attendeeType)
public enum AttendeeEntityType: String, Sendable {
    case individual
    case group
    case resource
    case room
    case unknown

    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .individual: DisplayRepresentation(title: "attendeeTypeIndividualLabel"),
        .group: DisplayRepresentation(title: "attendeeTypeGroupLabel"),
        .resource: DisplayRepresentation(title: "attendeeTypeResourceLabel"),
        .room: DisplayRepresentation(title: "attendeeTypeRoomLabel"),
        .unknown: DisplayRepresentation(title: "attendeeTypeUnknownLabel")
    ]
}

@available(iOS 27.0, *)
public extension AttendeeEntityType {
    init(attendeeType: AttendeeType) {
        switch attendeeType {
        case .individual:
            self = .individual
        case .group:
            self = .group
        case .resource:
            self = .resource
        case .room:
            self = .room
        case .unknown:
            self = .unknown
        }
    }

    var sdkValue: AttendeeType {
        switch self {
        case .individual:
            return .individual
        case .group:
            return .group
        case .resource:
            return .resource
        case .room:
            return .room
        case .unknown:
            return .unknown
        }
    }
}
