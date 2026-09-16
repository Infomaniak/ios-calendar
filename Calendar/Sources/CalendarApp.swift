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
import CalendarRootView
import ESDSCalendar
import InfomaniakCore
import InfomaniakDI
import SwiftUI

@main
struct CalendarApp: App {
    // periphery:ignore - Making sure the Sentry is initialized at a very early stage of the app launch.
    private let crashReportService = CrashReportService.shared
    // periphery:ignore - Making sure the DI is registered at a very early stage of the app launch.
    private let dependencyInjectionHook = CalendarTargetAssembly()

    @AppStorage(UserDefaults.shared.key(.firstWeekday), store: .shared)
    private var firstWeekday = DefaultPreferences.firstWeekday
    @AppStorage(UserDefaults.shared.key(.customTimeZoneIdentifier), store: .shared)
    private var customTimeZoneIdentifier = DefaultPreferences.timeZoneIdentifier
    @AppStorage(UserDefaults.shared.key(.useSystemTimeZone), store: .shared)
    private var useSystemTimeZone = DefaultPreferences.useLocalTime

    @StateObject private var rootViewState = RootViewState()

    private var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.firstWeekday = firstWeekday
        if !useSystemTimeZone,
           let customTimeZone = TimeZone(identifier: customTimeZoneIdentifier) {
            calendar.timeZone = customTimeZone
        }
        return calendar
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(rootViewState)
                .environment(\.calendar, calendar)
                .sceneLifecycle(willEnterForeground: willEnterForeground)
                .esdsTheme(.calendar)
        }
    }

    private func willEnterForeground() {
        if rootViewState.state != .onboarding && rootViewState.state != .preloading {
            @InjectService var appLaunchCounter: AppLaunchCounter
            appLaunchCounter.increase()
        }
    }
}
