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
    @State private var isExpanded = true

    public init() {}

    public var body: some View {
        List {
            CalendarListContentView(calendars: calendars)

            Section {
                DisclosureGroup("Réglages", isExpanded: $isExpanded) {
                    NavigationLink(destination: SettingsView()) {
                        CalendarResourcesAsset.Images.productCalendar.swiftUIImage
                        Text(CalendarResourcesStrings.settingsTitle)
                    }
                    Button {
                        openURL(URLConstants.helpAndSupportURL)
                    } label: {
                        Label {
                            Text(CalendarResourcesStrings.helpTitle)
                        } icon: {
                            CalendarResourcesAsset.Images.headset.swiftUIImage
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .task(id: calendarAccounts) {
            await observeCalendars()
        }
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            self.calendars = calendars.map { UICalendar(calendar: $0) }
        }
    }
}
