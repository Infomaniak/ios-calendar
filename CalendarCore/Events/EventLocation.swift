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

import MultiplatformCalendar

public enum EventLocation: Hashable, Sendable {
    case place(text: String)
    case room(uuid: String, room: LocationRoom?)
}

public extension EventLocation {
    init?(location: (any Location)?) {
        switch onEnum(of: location) {
        case .place(let place):
            guard !place.text.isEmpty else { return nil }
            self = .place(text: place.text)
        case .bookableRoom(let bookableRoom):
            if let resource = bookableRoom.resource {
                self = .room(uuid: bookableRoom.uuidValue, room: LocationRoom(resource: resource))
            } else {
                self = .room(uuid: bookableRoom.uuidValue, room: nil)
            }
        case nil:
            return nil
        }
    }

    var sdkValue: any Location {
        switch self {
        case .place(let text):
            return LocationPlace(text: text)
        case .room(let uuid, _):
            return LocationBookableRoom(uuid: uuid, resource: nil)
        }
    }
}
