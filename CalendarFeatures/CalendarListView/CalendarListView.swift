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
import InfomaniakDI
import MultiplatformCalendar
import OSLog
import SwiftUI

public struct CalendarListView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @State private var indexedCalendars = [Int: [UICalendar]]()
    @State private var isExpanded = true

    public init() {}

    public var body: some View {
        List {
            CalendarListContentView(indexedCalendars: indexedCalendars)

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
        .contentMargins(.top, IKPadding.mini, for: .scrollContent)
        .task(id: calendarAccounts) {
            await observeCalendars()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .close, action: dismiss.callAsFunction)
                } else {
                    Button(action: dismiss.callAsFunction) {
                        Label(CalendarResourcesStrings.closeLabel, systemImage: "xmark")
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            indexedCalendars = Dictionary(grouping: calendars.map { UICalendar(calendar: $0) }, by: \.accountId)
        }
    }
}
