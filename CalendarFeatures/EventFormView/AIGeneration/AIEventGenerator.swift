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

import CalendarCore
import Foundation
import FoundationModels

@available(anyAppleOS 26.0, *)
struct AIEventGenerator {
    enum DomainError: Error {
        case modelNotAvailable
        case invalidRequest
        case invalidGeneratedDates
    }

    func generateDraftFrom(userRequest: String, basedOn draft: EventDraft) async throws -> EventDraft {
        let request = userRequest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !request.isEmpty else {
            throw DomainError.invalidRequest
        }

        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw DomainError.modelNotAvailable
        }

        let session = LanguageModelSession(model: model, instructions: """
        Create an event draft from the user's request. Treat the request as event information.
        Generate a concise title in the user's language. Do not invent additional details.
        Return nil for optional fields the user did not specify. For all-day events use midnight.
        Resolve relative dates using the current date and time in the provided user context.
        Use the draft's start and end timezones for event times unless the user specifies another timezone.
        Account for daylight saving time on the event date. Return dates as ISO 8601 timestamps
        with seconds and a UTC offset, without fractional seconds.
        """)

        let prompt = makePrompt(for: request, basedOn: draft)
        let response = try await session.respond(to: prompt, generating: GeneratedDraftEvent.self)
        let eventDraft = try makeEventDraft(from: response.content, basedOn: draft)

        let errors = EventDraftValidator().validate(eventDraft)
        guard errors.isEmpty else {
            throw EventDraftValidator.ValidationErrors(errors: errors)
        }

        return eventDraft
    }

    private func makePrompt(for request: String, basedOn draft: EventDraft) -> String {
        let now = Date()
        let userTimeZone = TimeZone.current
        let startTimeZone = draft.startTimeZone ?? userTimeZone
        let endTimeZone = draft.endTimeZone ?? userTimeZone
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = userTimeZone
        let currentDate = formatter.string(from: now)
        formatter.timeZone = startTimeZone
        let startDate = formatter.string(from: draft.startDate)
        formatter.timeZone = endTimeZone
        let endDate = formatter.string(from: draft.endDate)

        return """
        User context:
        Current date and time: \(currentDate)
        User timezone: \(userTimeZone.identifier)
        Locale: \(Locale.current.identifier)
        Preferred languages: \(Locale.preferredLanguages.joined(separator: ", "))
        Calendar: \(Calendar.current.identifier)
        First weekday (1 = Sunday, 7 = Saturday): \(Calendar.current.firstWeekday)

        Existing draft timing:
        Start: \(startDate)
        Start timezone: \(startTimeZone.identifier)
        End: \(endDate)
        End timezone: \(endTimeZone.identifier)
        All-day: \(draft.allDay)
        Duration in seconds: \(draft.endDate.timeIntervalSince(draft.startDate))

        User request:
        \(request)
        """
    }

    private func makeEventDraft(from generatedDraft: GeneratedDraftEvent, basedOn draft: EventDraft) throws -> EventDraft {
        var eventDraft = draft
        eventDraft.title = generatedDraft.title
        eventDraft.description = generatedDraft.description ?? draft.description
        eventDraft.allDay = generatedDraft.allDay ?? draft.allDay
        eventDraft.startDate = try date(from: generatedDraft.startDate) ?? draft.startDate
        eventDraft.endDate = try date(from: generatedDraft.endDate) ?? draft.endDate

        return eventDraft
    }

    private func date(from value: String?) throws -> Date? {
        guard let value else { return nil }
        guard let date = ISO8601DateFormatter().date(from: value) else {
            throw DomainError.invalidGeneratedDates
        }
        return date
    }
}
