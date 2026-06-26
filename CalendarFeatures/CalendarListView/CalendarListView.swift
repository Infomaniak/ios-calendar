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
import CalendarSettingsView
import InfomaniakDI
import MultiplatformCalendar
import OSLog
import SwiftUI

public struct CalendarListView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts
    @Environment(\.openURL) private var openURL

    @State private var calendars = [UICalendar]()
    @State private var expandedAccounts: Set<Int> = []
    @State private var isExpanded = true

    public init() {}

    public var body: some View {
        List {
            ForEach(calendarAccounts) { account in
                Section {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedAccounts.contains(account.id) },
                            set: { isExpanding in
                                if isExpanding {
                                    expandedAccounts.insert(account.id)
                                } else {
                                    expandedAccounts.remove(account.id)
                                }
                            }
                        )
                    ) {
                        CalendarListContentView(calendars: calendarsFor(account: account))
                    } label: {
                        AccountCellView(account: account)
                    }
                }
            }

            Section {
                DisclosureGroup("Réglages", isExpanded: $isExpanded) {
                    NavigationLink(destination: SettingsView()) {
                        CalendarResourcesAsset.Images.productCalendar.swiftUIImage
                        Text(CalendarResourcesStrings.settingsTitle)
                    }
                    Button {
                        openURL(URL(string: "https://www.infomaniak.com/en/help")!)
                    } label: {
                        HStack {
                            CalendarResourcesAsset.Images.headset.swiftUIImage
                            Text(CalendarResourcesStrings.helpTitle)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task(id: calendarAccounts) {
            await observeCalendars()
        }
    }

    private func calendarsFor(account: CalendarAccount) -> [UICalendar] {
        calendars.filter { $0.accountId == account.id }
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            self.calendars = calendars.map { UICalendar(calendar: $0) }
        }
    }
}
