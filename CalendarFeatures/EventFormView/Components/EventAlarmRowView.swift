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

    @Binding var alarm: EventAlarmDraft

    private var selection: AlarmRowSelection {
        AlarmRowSelection(alarm: alarm)
    }

    var body: some View {
        if alarm.action.isEditable {
            Picker(selection: selectionBinding) {
                Section {
                    ForEach(AlarmOffset.presets) { preset in
                        Text(preset.label)
                            .tag(AlarmRowSelection.preset(preset))
                    }
                }
                if selection == .currentCustom {
                    Text(alarm.label)
                        .tag(AlarmRowSelection.currentCustom)
                }
                Text(CalendarResourcesStrings.customAlarmLabel)
                    .tag(AlarmRowSelection.custom)
            } label: {
                AlarmActionLabel(action: alarm.action)
            }
            .tint(theme.color.contentTertiary)
            .pickerStyle(.menu)
            .sheet(isPresented: $isShowingAddAlarmView) {
                NavigationStack {
                    AddAlarmView(alarm: alarm) { updatedAlarm in
                        alarm = updatedAlarm
                    }
                }
            }
        } else {
            AlarmRowView(alarmDraft: alarm)
        }
    }

    private var selectionBinding: Binding<AlarmRowSelection> {
        Binding(
            get: { selection },
            set: { newSelection in
                switch newSelection {
                case .preset(let preset):
                    alarm = alarm.with(offset: preset)
                case .currentCustom:
                    break
                case .custom:
                    isShowingAddAlarmView = true
                }
            }
        )
    }
}

private enum AlarmRowSelection: Hashable {
    case preset(AlarmOffset)
    case currentCustom
    case custom

    init(alarm: EventAlarmDraft) {
        guard let trigger = alarm.trigger else {
            self = .preset(.none)
            return
        }

        if let preset = AlarmOffset.presets.first(where: { $0.trigger == trigger }) {
            self = .preset(preset)
        } else {
            self = .currentCustom
        }
    }
}

#Preview {
    @Previewable @State var alarm = EventAlarmDraft.preview

    Form {
        Section {
            EventAlarmRowView(alarm: $alarm)
        }
    }
}
