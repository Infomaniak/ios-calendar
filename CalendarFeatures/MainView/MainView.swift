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

import CalendarCalendarListView
import CalendarCalendarView
import CalendarCore
import InfomaniakDI
@preconcurrency import MultiplatformCalendar
import OSLog
import SwiftUI

public struct MainView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var isShowingCalendarListView = false

    public init() {}

    public var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                CalendarListView()
            } detail: {
                NavigationStack {
                    CalendarView()
                }
            }
            .task(id: calendarAccounts) {
                await syncCalendars()
            }
        } else {
            NavigationStack {
                CalendarView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                isShowingCalendarListView = true
                            } label: {
                                Image(systemName: "list.bullet")
                            }
                        }
                    }
            }
            .task(id: calendarAccounts) {
                await syncCalendars()
            }
            .sheet(isPresented: $isShowingCalendarListView) {
                CalendarListView()
            }
        }
    }

    private func syncCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph

        for calendarAccount in calendarAccounts {
            do {
                try await calendarSDK.calendarManager.syncCalendars(accountId: Int64(calendarAccount.id))
            } catch {
                Logger.view.error("Failed to sync calendars for account \(calendarAccount.id): \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    MainView()
}
