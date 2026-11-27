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

public enum NavigationDestination: Equatable, Sendable {
    case event(occurrenceId: String)
    case newEvent
}

public struct UniversalLinkHandler: Sendable {
    public init() {}

    public func handlePossibleUniversalLink(_ url: URL) -> NavigationDestination? {
        if let widgetLink = tryToHandleWidgetLink(url) {
            return widgetLink
        }

        return nil
    }

    private func tryToHandleWidgetLink(_ url: URL) -> NavigationDestination? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == DeeplinkConstants.scheme else {
            return nil
        }

        switch components.host {
        case DeeplinkConstants.widgetEventHost:
            guard let occurrenceId = components.queryItems?
                .first(where: { $0.name == DeeplinkConstants.occurrenceIdQueryItem })?.value,
                !occurrenceId.isEmpty else {
                return nil
            }
            return .event(occurrenceId: occurrenceId)
        case DeeplinkConstants.widgetNewEventHost:
            return .newEvent
        default:
            return nil
        }
    }
}
