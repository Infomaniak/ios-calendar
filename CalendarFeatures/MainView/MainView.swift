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
import Contacts
import InfomaniakDI
@preconcurrency import MultiplatformCalendar
import OSLog
import SwiftUI

public struct MainView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init() {}

    public var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                RegularMainView()
            } else {
                CompactMainView()
            }
        }
        .task(id: calendarAccounts) {
            syncCalendarsAndContacts()
            await askForPermissions()
        }
        .sceneLifecycle(willEnterForeground: willEnterForeground)
    }

    private func willEnterForeground() {
        syncCalendarsAndContacts()

        Task {
            await askForPermissions()

            @InjectService var eventAlarmNotification: EventAlarmNotificationsService
            await eventAlarmNotification.scheduleNotificationsForEventAlarms()
        }
    }

    private func askForPermissions() async {
        guard !calendarAccounts.isEmpty else { return }

        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            do {
                let contactsPermissionGranted = try await CNContactStore().requestAccess(for: .contacts)
                if contactsPermissionGranted {
                    syncCalendarsAndContacts()
                }
            } catch {
                Logger.general.error("Failed to request contacts permission: \(error.localizedDescription)")
            }
        }

        await NotificationsHelper.askForPermissions()
    }

    private func syncCalendarsAndContacts() {
        Task {
            @InjectService var syncHelper: CalendarSyncHelper
            await syncHelper.sync()
        }
    }
}

#Preview {
    MainView()
}
