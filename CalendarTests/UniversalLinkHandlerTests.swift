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
import Testing

struct UniversalLinkHandlerTests {
    @Test func widgetEventURL() {
        let occurrenceId = "1:42:abc/def?x=1&y=2#3"
        let url = DeeplinkConstants.eventURL(occurrenceId: occurrenceId)

        #expect(UniversalLinkHandler().handlePossibleUniversalLink(url) == .event(occurrenceId: occurrenceId))
    }

    @Test func widgetNewEventURL() {
        #expect(UniversalLinkHandler().handlePossibleUniversalLink(DeeplinkConstants.newEventURL) == .newEvent)
    }

    @Test(arguments: [
        "https://widget-event?occurrence_id=1",
        "com.infomaniak.calendar://unknown?occurrence_id=1",
        "com.infomaniak.calendar://widget-event",
        "com.infomaniak.calendar://widget-event?occurrence_id="
    ])
    func unhandledURLs(_ string: String) throws {
        let url = try #require(URL(string: string))
        #expect(UniversalLinkHandler().handlePossibleUniversalLink(url) == nil)
    }
}
