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
import DesignSystem
import ESDSFoundation
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

public struct CalendarListView: View {
    @Environment(\.esdsTheme) private var theme
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var indexedCalendars = [Int: [UICalendar]]()

    public init() {}

    public var body: some View {
        List {
            CalendarListContentView(indexedCalendars: indexedCalendars)

            Section {
                NavigationLink(destination: AccountsListContentView()) {
                    Label {
                        Text(CalendarResourcesStrings.accountsTitle)
                            .foregroundStyle(theme.color.contentPrimary)
                    } icon: {
                        CalendarResourcesAsset.Images.circleUser.swiftUIImage
                    }
                }

                NavigationLink(destination: SettingsView()) {
                    Label {
                        Text(CalendarResourcesStrings.settingsTitle)
                            .foregroundStyle(theme.color.contentPrimary)
                    } icon: {
                        CalendarResourcesAsset.Images.cog.swiftUIImage
                    }
                }

                Link(destination: URLConstants.helpAndSupportURL) {
                    Label {
                        Text(CalendarResourcesStrings.helpTitle)
                            .foregroundStyle(theme.color.contentPrimary)
                    } icon: {
                        CalendarResourcesAsset.Images.headset.swiftUIImage
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text(CalendarResourcesStrings.configurationMenuSectionTitle)
                    .foregroundStyle(theme.color.contentSecondary)
            }
        }
        .task(id: calendarAccounts) {
            await observeCalendars()
        }
        .listSectionSpacing(.compact)
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            indexedCalendars = Dictionary(grouping: calendars.map { UICalendar(calendar: $0) }, by: \.accountId)
        }
    }
}
