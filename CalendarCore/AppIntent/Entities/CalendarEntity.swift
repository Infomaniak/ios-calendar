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
import InfomaniakDI
import MultiplatformCalendar

@available(iOS 27.0, *)
@AppEntity(schema: .calendar.calendar)
public struct CalendarEntity: IndexedEntity, Sendable {
    public static let defaultQuery = CalendarEntityQuery()

    public let id: String
    public var title: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    public struct CalendarEntityQuery: EntityQuery {
        public init() {}

        public func entities(for identifiers: [CalendarEntity.ID]) async throws -> [CalendarEntity] {
            @InjectService var calendarSDK: CalendarCoreGraph
            let calendars = await calendarSDK.calendarManager.flatCalendars()
            let calendarsById = Dictionary(calendars.map { ($0.idValue, $0) }) { first, _ in first }

            return identifiers.compactMap { identifier in
                guard let calendar = calendarsById[identifier] else { return nil }
                return CalendarEntity(calendar: calendar)
            }
        }

        public func suggestedEntities() async throws -> [CalendarEntity] {
            @InjectService var calendarSDK: CalendarCoreGraph
            return await calendarSDK.calendarManager.flatCalendars().compactMap { calendar in
                guard calendar.isVisible else { return nil }
                return CalendarEntity(calendar: calendar)
            }
        }
    }
}

@available(iOS 27.0, *)
public extension CalendarEntity {
    init(calendar: MultiplatformCalendar.Calendar) {
        id = calendar.idValue
        title = calendar.displayName
    }
}
