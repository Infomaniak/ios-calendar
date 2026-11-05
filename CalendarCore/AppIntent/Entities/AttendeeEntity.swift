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
import Foundation
import InfomaniakDI
import MultiplatformCalendar

@available(iOS 27.0, *)
@AppEntity(schema: .calendar.attendee)
public struct AttendeeEntity: Sendable {
    public static let defaultQuery = AttendeeEntityQuery()

    public let id: Identifier

    public var person: IntentPerson
    public var status: AttendeeEntityStatus?
    public var isAttendanceOptional: Bool
    public var type: AttendeeEntityType?

    public var displayRepresentation: DisplayRepresentation {
        let name: String
        switch person.name {
        case .displayName(let displayName):
            name = displayName
        case .components(let components):
            name = components.formatted()
        case .unknown:
            name = id.email
        @unknown default:
            name = id.email
        }

        return DisplayRepresentation(title: "\(name)")
    }

    public init(
        id: Identifier,
        person: IntentPerson,
        status: AttendeeEntityStatus?,
        isAttendanceOptional: Bool,
        type: AttendeeEntityType?
    ) {
        self.id = id
        self.person = person
        self.status = status
        self.isAttendanceOptional = isAttendanceOptional
        self.type = type
    }

    public struct AttendeeEntityQuery: EntityStringQuery {
        private static let maximumContactCount: Int32 = 5

        public init() {}

        public func entities(for identifiers: [AttendeeEntity.ID]) async throws -> [AttendeeEntity] {
            identifiers.map { AttendeeEntity(email: $0.email, displayName: $0.name) }
        }

        public func entities(matching string: String) async throws -> [AttendeeEntity] {
            let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return [] }

            @InjectService var calendarSDK: CalendarCoreGraph
            let contacts = try await calendarSDK.contactsManager.search(query: query, limit: Self.maximumContactCount)

            var seenEmails = Set<String>()
            return contacts
                .map { AttendeeEntity(email: Self.normalizedEmail($0.email), displayName: $0.name) }
                .filter { seenEmails.insert($0.id.email).inserted }
        }

        fileprivate static func normalizedEmail(_ email: String) -> String {
            email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
}

@available(iOS 27.0, *)
public extension AttendeeEntity {
    struct Identifier: EntityIdentifierConvertible, Hashable, Sendable {
        private static let separator: Character = "|"

        public let email: String
        public let name: String?

        public var entityIdentifierString: String {
            guard let name else { return email }
            return "\(email)\(Self.separator)\(name)"
        }

        public init(email: String, name: String?) {
            self.email = email
            if let name, !name.isEmpty {
                self.name = name
            } else {
                self.name = nil
            }
        }

        public static func entityIdentifier(for entityIdentifierString: String) -> Identifier? {
            guard let separatorIndex = entityIdentifierString.firstIndex(of: separator) else {
                return Identifier(email: entityIdentifierString, name: nil)
            }
            return Identifier(
                email: String(entityIdentifierString[..<separatorIndex]),
                name: String(entityIdentifierString[entityIdentifierString.index(after: separatorIndex)...])
            )
        }
    }

    init(attendee: Attendee) {
        let email = AttendeeEntityQuery.normalizedEmail(attendee.email)
        id = Identifier(email: email, name: attendee.displayName)
        person = IntentPerson(email: email, displayName: attendee.displayName)
        status = AttendeeEntityStatus(participationStatus: attendee.status)
        isAttendanceOptional = attendee.role == .optional
        type = AttendeeEntityType(attendeeType: attendee.type)
    }

    init(email: String, displayName: String?) {
        id = Identifier(email: email, name: displayName)
        person = IntentPerson(email: email, displayName: displayName)
        status = nil
        isAttendanceOptional = false
        type = .individual
    }
}

@available(iOS 27.0, *)
extension IntentPerson {
    init(email: String, displayName: String?) {
        let name: IntentPerson.Name
        if let displayName, !displayName.isEmpty {
            name = .displayName(displayName)
        } else {
            name = .unknown
        }

        self.init(identifier: .applicationDefined(email), name: name, handle: IntentPerson.Handle(emailAddress: email))
    }
}
