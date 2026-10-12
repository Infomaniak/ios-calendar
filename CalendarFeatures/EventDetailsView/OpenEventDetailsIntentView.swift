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
import CalendarCoreUI
import CalendarResources
import DesignSystem
import InfomaniakDI
import MultiplatformCalendar
import OSLog
import SwiftUI

public struct OpenEventDetailsIntentView: View {
    private struct ResolvedIntent {
        let event: UIEventDetails
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var resolvedIntent: ResolvedIntent?
    @State private var errorMessage: String?

    private let occurrenceId: String

    public init(occurrenceId: String) {
        self.occurrenceId = occurrenceId
    }

    public var body: some View {
        Group {
            if let resolvedIntent {
                EventDetailsView(event: resolvedIntent.event)
            } else {
                NavigationStack {
                    Group {
                        if let errorMessage {
                            Text(errorMessage)
                                .padding(value: .medium)
                        } else {
                            ProgressView()
                        }
                    }
                    .closeToolbarItem(dismiss: dismiss)
                }
            }
        }
        .task {
            await initFromIntent()
        }
    }

    private func initFromIntent() async {
        resolvedIntent = nil
        errorMessage = nil
        do {
            @InjectService var calendarSDK: CalendarCoreGraph
            let id = OccurrenceId.companion.parse(value: occurrenceId)
            guard let occurrence = try await calendarSDK.calendarManager.getOccurrence(occurrenceId: id) else {
                throw CalendarError.eventOccurrenceNotFound
            }
            try Task.checkCancellation()
            let email = calendarAccounts[Int(occurrence.accountIdValue)]?.user.email
            resolvedIntent = ResolvedIntent(event: UIEventDetails(event: occurrence, userEmail: email))
        } catch is CancellationError {
            return
        } catch {
            Logger.view.error("Failed to load event details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
