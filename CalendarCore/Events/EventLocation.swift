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

public enum EventLocation: Hashable, Sendable {
    case place(name: String)
    case room(id: String, name: String, accountId: Int64)

    public var stringValue: String {
        switch self {
        case .place(let name):
            return name
        case .room(_, let name, _):
            return name
        }
    }

    /// Locations are persisted as text, so room metadata must not make an otherwise unchanged location differ.
    public static func == (lhs: EventLocation, rhs: EventLocation) -> Bool {
        lhs.stringValue == rhs.stringValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stringValue)
    }
}
