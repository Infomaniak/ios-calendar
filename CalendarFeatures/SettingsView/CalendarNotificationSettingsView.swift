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
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

struct CalendarNotificationSettingsView: View {
    @State private var state: UICalendarNotificationState

    let calendar: UICalendar

    private var isEnabledBinding: Binding<Bool> {
        Binding {
            state != .disabled
        } set: { isEnabled in
            updateState(isEnabled ? .enabled : .disabled)
        }
    }

    init(calendar: UICalendar, state: UICalendarNotificationState) {
        self.calendar = calendar
        _state = State(initialValue: state)
    }

    var body: some View {
        List {
            Section {
                Toggle(CalendarResourcesStrings.calendarNotificationSettingsEnableLabel, isOn: isEnabledBinding)
                    .toggleStyle(.switch)
            } footer: {
                Text(CalendarResourcesStrings.calendarNotificationSettingsDescription)
            }
        }
        .navigationTitle(CalendarResourcesStrings.calendarNotificationSettingsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func updateState(_ newState: UICalendarNotificationState) {
        let previousState = state
        state = newState

        Task {
            @InjectService var calendarSDK: CalendarCoreGraph
            do {
                try await calendarSDK.calendarManager.updateCalendarNotificationState(
                    calendarId: calendar.id,
                    state: newState.sdkValue
                )
                rescheduleEventAlarmNotifications()
            } catch {
                state = previousState
            }
        }
    }
}

#Preview {
    NavigationStack {
        CalendarNotificationSettingsView(calendar: UICalendarSection.preview.calendars[0], state: .enabled)
    }
}
