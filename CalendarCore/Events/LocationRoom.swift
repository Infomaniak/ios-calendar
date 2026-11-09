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

public struct LocationRoom: Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let capacity: Int?
    public let floor: Int?

    public var location: EventLocation {
        .room(uuid: id, room: self)
    }

    public init(id: String, name: String, capacity: Int?, floor: Int?) {
        self.id = id
        self.name = name
        self.capacity = capacity
        self.floor = floor
    }
}

public extension LocationRoom {
    init(resource: BookableResource) {
        self.init(
            id: resource.uuidValue,
            name: resource.name,
            capacity: resource.capacity?.intValue,
            floor: resource.floor?.intValue
        )
    }
}
