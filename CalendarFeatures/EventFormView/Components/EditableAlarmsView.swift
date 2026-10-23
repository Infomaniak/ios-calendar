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
        ForEach([UIAlarmAction.email, .display]) { action in
            EventAlarmTypeRowsView(alarms: $alarms, action: action)
        }

        ForEach(otherAlarms) { alarm in
            EventAlarmRowView(alarm: .constant(alarm))
        }
    }
}

struct EventAlarmTypeRowsView: View {
    @State private var newAlarm: EventAlarmDraft

    @Binding var alarms: [EventAlarmDraft]

    let action: UIAlarmAction
    private var sortedAlarms: [EventAlarmDraft] {
        alarms.filter { $0.action == action }.sorted()
    }

    private var newAlarmBinding: Binding<EventAlarmDraft> {
        Binding(
            get: { newAlarm },
            set: { alarm in
                if alarm.trigger != nil {
                    alarms.append(alarm)
                    newAlarm = EventAlarmDraft(offset: .none, action: action)
                }
            }
        )
    }

    init(alarms: Binding<[EventAlarmDraft]>, action: UIAlarmAction) {
        _newAlarm = State(initialValue: EventAlarmDraft(offset: .none, action: action))
        _alarms = alarms
        self.action = action
    }

    var body: some View {
        ForEach(sortedAlarms) { alarm in
            EventAlarmRowView(alarm: alarmBinding(for: alarm))
        }

        EventAlarmRowView(alarm: newAlarmBinding)
    }

    func alarmBinding(for alarm: EventAlarmDraft) -> Binding<EventAlarmDraft> {
        Binding(
            get: { alarms.first { $0.id == alarm.id } ?? alarm },
            set: { updatedAlarm in
                if updatedAlarm.trigger == nil {
                    alarms.removeAll { $0.id == alarm.id }
                } else {
                    alarms = alarms.map { $0.id == alarm.id ? updatedAlarm : $0 }
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
