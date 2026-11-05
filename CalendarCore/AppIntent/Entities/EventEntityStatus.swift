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
@AppEnum(schema: .calendar.eventStatus)
public enum EventEntityStatus: String, Sendable {
    case confirmed
    case tentative
    case cancelled

    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .confirmed: DisplayRepresentation(title: "eventStatusConfirmedLabel"),
        .tentative: DisplayRepresentation(title: "eventStatusTentativeLabel"),
        .cancelled: DisplayRepresentation(title: "eventStatusCancelledLabel")
    ]
}

@available(iOS 27.0, *)
public extension EventEntityStatus {
    init(eventStatus: EventStatus) {
        switch eventStatus {
        case .confirmed:
            self = .confirmed
        case .tentative:
            self = .tentative
        case .cancelled:
            self = .cancelled
        }
    }
}
