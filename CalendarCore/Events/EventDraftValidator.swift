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
import Foundation

public struct EventDraftValidator: Sendable {
    public enum ValidationError: LocalizedError, Hashable, CaseIterable {
        case titleTooLong
        case descriptionTooLong
        case tooManyAttendees
        case missingCalendar
        case invalidDates

        public var errorDescription: String {
            switch self {
            case .titleTooLong, .descriptionTooLong:
                return "Vous avez dépassé la limite de caractères"
            case .tooManyAttendees:
                return "Vous ne pouvez pas avoir plus de \(maximumAttendeeCount) invités"
            case .missingCalendar:
                return "Vous devez sélectionner un calendrier"
            case .invalidDates:
                return "Dates invalides"
            }
        }
    }

    public struct ValidationErrors: LocalizedError, Equatable {
        public let errors: Set<ValidationError>

        public var errorDescription: String? {
            ValidationError.allCases
                .filter(errors.contains)
                .map(\.errorDescription)
                .joined(separator: "\n")
        }
    }

    public static let maximumTitleCharacterCount = 1000
    public static let maximumDescriptionCharacterCount = 5000
    public static let maximumAttendeeCount = 100

    public init() {}

    public func validate(_ draft: EventDraft) -> Set<ValidationError> {
        var errors = Set<ValidationError>()

        if draft.title.count > Self.maximumTitleCharacterCount {
            errors.insert(.titleTooLong)
        }

        if draft.description.count > Self.maximumDescriptionCharacterCount {
            errors.insert(.descriptionTooLong)
        }

        if draft.attendees.count > Self.maximumAttendeeCount {
            errors.insert(.tooManyAttendees)
        }

        if draft.calendarId?.isEmpty != false {
            errors.insert(.missingCalendar)
        }

        if let dateError = validateDates(draft: draft) {
            errors.insert(dateError)
        }

        return errors
    }

    private func validateDates(draft: EventDraft) -> ValidationError? {
        var calendar = Calendar(identifier: .gregorian)

        calendar.timeZone = draft.startTimeZone ?? .current
        let start = calendar.dateComponents([.year, .month, .day], from: draft.startDate)

        calendar.timeZone = draft.endTimeZone ?? .current
        let end = calendar.dateComponents([.year, .month, .day], from: draft.endDate)

        calendar.timeZone = .gmt

        if let startDay = calendar.date(from: start), let endDay = calendar.date(from: end) {
            if endDay <= startDay {
                return .invalidDates
            }
        } else {
            return .invalidDates
        }

        return nil
    }
}
