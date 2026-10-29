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
import SwiftUI

struct EventAlarmRowView: View {
    @Environment(\.esdsTheme) private var theme

    @State private var isShowingAddAlarmView = false

    @Binding var alarm: EventAlarmDraft?

    let action: UIAlarmAction

    private var noneLabel: String {
        action == .display
            ? CalendarResourcesStrings.alarmOffsetNoneNotification
            : CalendarResourcesStrings.alarmOffsetNone
    }

    private var selection: AlarmRowSelection {
        AlarmRowSelection(alarm: alarm)
    }

    private var selectionBinding: Binding<AlarmRowSelection> {
        Binding(
            get: { selection },
            set: { newSelection in
                switch newSelection {
                case .none:
                    alarm = nil
                case .preset(let preset):
                    if let alarm {
                        self.alarm = alarm.newWith(offset: preset)
                    } else {
                        alarm = EventAlarmDraft(action: action, offset: preset)
                    }
                case .currentCustom:
                    break
                case .custom:
                    isShowingAddAlarmView = true
                }
            }
        )
    }

    var body: some View {
        if action.isEditable {
            Picker(selection: selectionBinding) {
                Section {
                    Text(noneLabel)
                        .tag(AlarmRowSelection.none)
                    ForEach(AlarmOffset.allCases) { preset in
                        Text(preset.label)
                            .tag(AlarmRowSelection.preset(preset))
                    }
                }
                if selection == .currentCustom, let alarm {
                    Text(alarm.label)
                        .tag(AlarmRowSelection.currentCustom)
                }
                Text(CalendarResourcesStrings.customAlarmLabel)
                    .tag(AlarmRowSelection.custom)
            } label: {
                AlarmActionLabel(action: action)
            }
            .tint(theme.color.contentTertiary)
            .pickerStyle(.menu)
            .sheet(isPresented: $isShowingAddAlarmView) {
                NavigationStack {
                    AddAlarmView(alarm: alarm ?? EventAlarmDraft(action: action, offset: .fiveMinutesBefore)) { updatedAlarm in
                        alarm = updatedAlarm
                    }
                }
            }
        } else if let alarm {
            AlarmRowView(alarmDraft: alarm)
        }
    }
}

private enum AlarmRowSelection: Hashable {
    case none
    case preset(AlarmOffset)
    case currentCustom
    case custom

    init(alarm: EventAlarmDraft?) {
        guard let alarm else {
            self = .none
            return
        }

        if let preset = AlarmOffset(trigger: alarm.trigger) {
            self = .preset(preset)
        } else {
            self = .currentCustom
        }
    }
}

#Preview {
    @Previewable @State var alarm: EventAlarmDraft? = .preview

    Form {
        Section {
            EventAlarmRowView(alarm: $alarm, action: .display)
        }
    }
}
