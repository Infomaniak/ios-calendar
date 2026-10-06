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
import CalendarResources
import DesignSystem
import ESDSFoundation
import SwiftUI

struct EventAlarmRow: View {
    @Environment(\.esdsTheme) private var theme

    @State private var selection: AlarmRowSelection
    @State private var isShowingCustomReminder = false

    let alarm: UIEventAlarm
    let onSelectOffset: (AlarmOffset) -> Void
    let onSelectCustomReminder: (UIEventAlarm) -> Void

    init(
        alarm: UIEventAlarm,
        onSelectOffset: @escaping (AlarmOffset) -> Void,
        onSelectCustomReminder: @escaping (UIEventAlarm) -> Void
    ) {
        self.alarm = alarm
        self.onSelectOffset = onSelectOffset
        self.onSelectCustomReminder = onSelectCustomReminder
        _selection = State(initialValue: AlarmRowSelection(alarm: alarm))
    }

    var body: some View {
        if alarm.action.isEditable {
            editableRow
        } else {
            LabeledContent {
                Text(alarm.label)
                    .foregroundStyle(theme.color.contentTertiary)
            } label: {
                rowLabel
            }
        }
    }

    private var rowLabel: some View {
        Label(alarm.action.label, image: alarm.action.icon)
            .labelStyle(.formLabel)
    }

    private var editableRow: some View {
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
            rowLabel
        }
        .tint(theme.color.contentTertiary)
        .pickerStyle(.menu)
        .onChange(of: alarm) { _, newAlarm in
            selection = AlarmRowSelection(alarm: newAlarm)
        }
        .onChange(of: isShowingCustomReminder) { _, isShowing in
            if !isShowing {
                selection = AlarmRowSelection(alarm: alarm)
            }
        }
        .sheet(isPresented: $isShowingCustomReminder) {
            NavigationStack {
                AddReminderView(alarm: alarm) { updatedAlarm in
                    onSelectCustomReminder(updatedAlarm)
                }
            }
        }
    }

    private var selectionBinding: Binding<AlarmRowSelection> {
        Binding(
            get: { selection },
            set: { newSelection in
                switch newSelection {
                case .preset(let preset):
                    selection = newSelection
                    onSelectOffset(preset)
                case .currentCustom:
                    break
                case .custom:
                    isShowingCustomReminder = true
                }
            }
        )
    }
}

private enum AlarmRowSelection: Hashable {
    case preset(AlarmOffset)
    case currentCustom
    case custom

    init(alarm: UIEventAlarm) {
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
    Form {
        Section {
            EventAlarmRow(
                alarm: .preview,
                onSelectOffset: { _ in },
                onSelectCustomReminder: { _ in }
            )
        }
    }
}
