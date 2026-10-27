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
import SwiftUI

struct EditableAlarmsView: View {
    @Binding var alarms: [EventAlarmDraft]

    private var otherAlarms: [EventAlarmDraft] {
        alarms.filter { !$0.action.isEditable }.sorted()
    }

    var body: some View {
        ForEach([UIAlarmAction.display, UIAlarmAction.email]) { action in
            EventAlarmTypeRowsView(alarms: $alarms, action: action)
        }

        ForEach(otherAlarms) { alarm in
            AlarmRowView(alarmDraft: alarm)
        }
    }
}

struct EventAlarmTypeRowsView: View {
    @Binding var alarms: [EventAlarmDraft]

    let action: UIAlarmAction
    private var sortedAlarms: [EventAlarmDraft] {
        alarms.filter { $0.action == action }.sorted()
    }

    var newAlarmBinding: Binding<EventAlarmDraft?> {
        Binding(
            get: { nil },
            set: { alarm in
                if let alarm {
                    alarms.append(alarm)
                }
            }
        )
    }

    var body: some View {
        ForEach(sortedAlarms) { alarm in
            EventAlarmRowView(alarm: alarmBinding(for: alarm), action: action)
        }

        EventAlarmRowView(alarm: newAlarmBinding, action: action)
    }

    func alarmBinding(for alarm: EventAlarmDraft) -> Binding<EventAlarmDraft?> {
        Binding(
            get: { alarms.first { $0.id == alarm.id } },
            set: { updatedAlarm in
                if let updatedAlarm {
                    alarms = alarms.map { $0.id == alarm.id ? updatedAlarm : $0 }
                } else {
                    alarms.removeAll { $0.id == alarm.id }
                }
            }
        )
    }
}

#Preview {
    @Previewable @State var alarms = EventAlarmDraft.previews

    Form {
        Section {
            EditableAlarmsView(alarms: $alarms)
        }
    }
}
