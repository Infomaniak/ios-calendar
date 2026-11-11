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
import ESDSFoundation
import ESDSSymbols
import InfomaniakCoreUIResources
import SwiftUI

public struct SettingsView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    @AppStorage(UserDefaults.shared.key(.theme), store: .shared)
    private var appTheme = DefaultPreferences.theme
    @AppStorage(UserDefaults.shared.key(.firstWeekday), store: .shared)
    private var firstWeekday = DefaultPreferences.firstWeekday
    @AppStorage(UserDefaults.shared.key(.showWeekNumbers), store: .shared)
    private var showWeekNumbers = DefaultPreferences.showWeekNumbers
    @AppStorage(UserDefaults.shared.key(.defaultEventDuration), store: .shared)
    private var defaultEventDuration = DefaultPreferences.defaultEventDuration
    @AppStorage(UserDefaults.shared.key(.customTimeZoneIdentifier), store: .shared)
    private var customTimeZoneIdentifier: String?

    private var weekdayIndices: [Int] {
        let symbols = calendar.weekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        guard symbols.indices.contains(firstWeekdayIndex) else {
            return Array(symbols.indices)
        }

        return Array(symbols.indices[firstWeekdayIndex...]) + Array(symbols.indices[..<firstWeekdayIndex])
    }

    private var customTimeZone: TimeZone {
        customTimeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
    }

    private var useSystemTimeZoneBinding: Binding<Bool> {
        Binding {
            customTimeZoneIdentifier == nil
        } set: { useSystemTimeZone in
            customTimeZoneIdentifier = useSystemTimeZone ? nil : TimeZone.current.identifier
        }
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
                Picker(selection: $appTheme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.title)
                            .tag(theme)
                    }
                } label: {
                    Label(CoreUILocalizable.themeTitle, symbol: ESDSSymbols.smartphoneTablet)
                }
                .pickerStyle(.navigationLink)

                Picker(selection: $firstWeekday) {
                    ForEach(weekdayIndices, id: \.self) { weekdayIndex in
                        Text(calendar.weekdaySymbols[weekdayIndex].localizedCapitalized)
                            .tag(weekdayIndex + 1)
                    }
                } label: {
                    Label(CalendarResourcesStrings.generalSettingsStartOfWeekLabel, symbol: ESDSSymbols.calendarDots)
                }
                .pickerStyle(.navigationLink)

                Toggle(CalendarResourcesStrings.generalSettingsShowWeekNumbersLabel, isOn: $showWeekNumbers)
                    .toggleStyle(.switch)
            } header: {
                Text(CalendarResourcesStrings.generalSettingsDisplayLabel)
            }

            Section {
                Picker(selection: $defaultEventDuration) {
                    ForEach(DefaultEventDuration.defaultCases, id: \.self) { duration in
                        Text(
                            Duration.seconds(duration.timeInterval)
                                .formatted(.units(allowed: [.hours, .minutes], width: .condensedAbbreviated))
                        )
                        .tag(duration)
                    }
                } label: {
                    Label(CalendarResourcesStrings.generalSettingsDefaultEventDurationLabel, symbol: ESDSSymbols.clock)
                }
                .pickerStyle(.navigationLink)

                Toggle(isOn: useSystemTimeZoneBinding) {
                    Label(CalendarResourcesStrings.generalSettingsUseDeviceTimeZoneLabel, symbol: ESDSSymbols.globe)
                }
                .toggleStyle(.switch)

                NavigationLink {
                    TimeZoneListView(timeZone: customTimeZoneBinding, referenceDate: .now)
                } label: {
                    LabeledContent {
                        Text(customTimeZone, format: .timeZone(.displayName))
                    } label: {
                        Text(CalendarResourcesStrings.timeZoneLabel)
                    }
                }
                .disabled(customTimeZoneIdentifier == nil)
            } header: {
                Text(CalendarResourcesStrings.calendarsMenuSectionTitle)
            }

            Section {
                Link(destination: URLConstants.helpAndSupportURL) {
                    HStack {
                        Label {
                            Text(CalendarResourcesStrings.generalSettingsContactSupportLabel)
                                .foregroundStyle(theme.color.contentPrimary)
                        } icon: {
                            ESDSSymbols.headset.image
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ESDSSymbols.squareArrowOutUpRight.image
                    }
                }
            } header: {
                Text(CalendarResourcesStrings.generalSettingsHelpAndPrivacyLabel)
            }
        }
        .navigationTitle(CalendarResourcesStrings.settingsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
