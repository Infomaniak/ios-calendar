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

import Foundation
import FoundationModels

@available(anyAppleOS 26.0, *)
@Generable(description: "Event details.")
struct GeneratedDraftEvent {
    @Guide(description: "A concise, nonempty event title in the user's language.")
    var title: String

    @Guide(description: "Additional event notes explicitly provided by the user; nil if unspecified.")
    var description: String?

    @Guide(description: "Whether the user requests an all-day event; nil if unspecified.")
    var allDay: Bool?

    @Guide(description: "Start of the event as an ISO 8601 date and time with a timezone; nil if unspecified.")
    var startDate: String?

    @Guide(description: "End of the event as an ISO 8601 date and time with a timezone; nil if unspecified.")
    var endDate: String?
}
