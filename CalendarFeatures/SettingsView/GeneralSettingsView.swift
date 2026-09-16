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
import ESDSFoundation
import InfomaniakCoreUIResources
import SwiftUI

public struct GeneralSettingsView: View {
    @Environment(\.esdsTheme) private var theme
    @Environment(\.calendar) private var calendar

    @AppStorage(UserDefaults.shared.key(.theme), store: .shared)
    private var appTheme = DefaultPreferences.theme
    @AppStorage(UserDefaults.shared.key(.firstWeekday), store: .shared)
    private var firstWeekday = DefaultPreferences.firstWeekday
    @AppStorage(UserDefaults.shared.key(.displayWeekends), store: .shared)
    private var displayWeekends = DefaultPreferences.displayWeekends
    @AppStorage(UserDefaults.shared.key(.defaultEventDuration), store: .shared)
    private var defaultEventDuration = DefaultPreferences.defaultEventDuration
    @AppStorage(UserDefaults.shared.key(.useSystemTimeZone), store: .shared)
    private var useSystemTimeZone = DefaultPreferences.useLocalTime
    @AppStorage(UserDefaults.shared.key(.customTimeZoneIdentifier), store: .shared)
    private var customTimeZoneIdentifier = DefaultPreferences.timeZoneIdentifier

    private var weekdayIndices: [Int] {
        let symbols = calendar.weekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        guard symbols.indices.contains(firstWeekdayIndex) else {
            return Array(symbols.indices)
        }

        return Array(symbols.indices[firstWeekdayIndex...]) + Array(symbols.indices[..<firstWeekdayIndex])
    }

    private var customTimeZone: TimeZone {
        TimeZone(identifier: customTimeZoneIdentifier) ?? .current
    }

    private var customTimeZoneBinding: Binding<TimeZone> {
        Binding {
            customTimeZone
        } set: { timeZone in
            customTimeZoneIdentifier = timeZone.identifier
        }
    }

    public init() {}

    public var body: some View {
        List {
            Section {
                Picker(CoreUILocalizable.themeTitle, selection: $appTheme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.title)
                            .tag(theme)
                    }
                }
                .pickerStyle(.navigationLink)

                Picker(CalendarResourcesStrings.generalSettingsStartOfWeekLabel, selection: $firstWeekday) {
                    ForEach(weekdayIndices, id: \.self) { weekdayIndex in
                        Text(calendar.weekdaySymbols[weekdayIndex].localizedCapitalized)
                            .tag(weekdayIndex + 1)
                    }
                }
                .pickerStyle(.navigationLink)

                Toggle(CalendarResourcesStrings.generalSettingsShowWeekendsLabel, isOn: $displayWeekends)
                    .toggleStyle(.switch)
            } header: {
                Text(CalendarResourcesStrings.generalSettingsDisplayLabel)
            }

            Section {
                Picker(CalendarResourcesStrings.generalSettingsDefaultEventDurationLabel, selection: $defaultEventDuration) {
                    ForEach(DefaultEventDuration.defaultCases, id: \.self) { duration in
                        Text(
                            Duration.seconds(duration.timeInterval)
                                .formatted(.units(allowed: [.hours, .minutes], width: .condensedAbbreviated))
                        )
                        .tag(duration)
                    }
                }
                .pickerStyle(.navigationLink)

                Toggle(CalendarResourcesStrings.generalSettingsUseDeviceTimeZoneLabel, isOn: $useSystemTimeZone)
                    .toggleStyle(.switch)
                    .onChange(of: useSystemTimeZone) { _, newValue in
                        guard newValue else { return }
                        customTimeZoneIdentifier = TimeZone.current.identifier
                    }

                NavigationLink {
                    TimeZoneListView(timeZone: customTimeZoneBinding, referenceDate: .now)
                } label: {
                    LabeledContent {
                        Text(customTimeZone.formattedIdentifier)
                    } label: {
                        Text(CalendarResourcesStrings.timeZoneLabel)
                    }
                }
                .disabled(useSystemTimeZone)
            } header: {
                Text(CalendarResourcesStrings.calendarsMenuSectionTitle)
            }
        }
    }
}

#Preview {
    NavigationStack {
        GeneralSettingsView()
    }
}
