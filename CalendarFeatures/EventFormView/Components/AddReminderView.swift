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
import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var amount: Int
    @State private var period: ReminderPeriod
    @State private var action: UIAlarmAction

    let onAdd: (UIEventAlarm) -> Void

    init(alarm: UIEventAlarm, onAdd: @escaping (UIEventAlarm) -> Void) {
        let configuration = ReminderPeriod.configuration(for: alarm.trigger)
        _amount = State(initialValue: configuration.amount)
        _period = State(initialValue: configuration.period)
        _action = State(initialValue: alarm.action)
        self.onAdd = onAdd
    }

    var body: some View {
        Form {
            Section {
                LabeledContent(CalendarResourcesStrings.reminderTitle) {
                    Text(period.formattedDuration(amount: amount, locale: locale))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: .zero) {
                    Picker(CalendarResourcesStrings.otherReminderNumberLabel, selection: $amount) {
                        ForEach(1 ... 999, id: \.self) { value in
                            Text(value, format: .number.locale(locale))
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .accessibilityLabel(CalendarResourcesStrings.otherReminderNumberLabel)

                    Picker(CalendarResourcesStrings.otherReminderPeriodLabel, selection: $period) {
                        ForEach(ReminderPeriod.allCases) { option in
                            Text(option.unitLabel(amount: amount, locale: locale))
                                .tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .accessibilityLabel(CalendarResourcesStrings.otherReminderPeriodLabel)
                }
                .frame(height: 150)
                .clipped()
            }

            Section {
                Picker(CalendarResourcesStrings.otherReminderAlarmKindLabel, selection: $action) {
                    Text(CalendarResourcesStrings.notificationTypeEmail)
                        .tag(UIAlarmAction.email)
                    Text(CalendarResourcesStrings.notificationTypePush)
                        .tag(UIAlarmAction.display)
                }
                .pickerStyle(.menu)
            }
        }
        .navigationTitle(CalendarResourcesStrings.reminderTitle)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            CloseToolbarItem(action: dismiss.callAsFunction)

            ToolbarItem(placement: .confirmationAction) {
                ConfirmationButton(action: save)
            }
        }
    }

    private func save() {
        let trigger = UIAlarmTrigger.relative(
            offset: -Double(amount) * period.seconds,
            relatedTo: .start
        )
        onAdd(
            UIEventAlarm(
                action: action,
                trigger: trigger,
                attachments: [],
                attendees: [],
                description: nil,
                summary: nil
            )
        )
        dismiss()
    }
}

private enum ReminderPeriod: String, CaseIterable, Identifiable {
    case minutes
    case hours
    case days

    var id: Self {
        self
    }

    var seconds: TimeInterval {
        switch self {
        case .minutes: 60
        case .hours: 3600
        case .days: 86400
        }
    }

    var unit: Duration.UnitsFormatStyle.Unit {
        switch self {
        case .minutes: .minutes
        case .hours: .hours
        case .days: .days
        }
    }

    func formattedDuration(amount: Int, locale: Locale) -> String {
        Duration.seconds(Double(amount) * seconds)
            .formatted(.units(allowed: [unit], width: .wide).locale(locale))
    }

    func unitLabel(amount: Int, locale: Locale) -> String {
        let formatted = Duration.seconds(Double(amount) * seconds)
            .formatted(.units(allowed: [unit], width: .wide).locale(locale).attributed)
        return formatted.runs
            .filter { $0.measurement == .unit }
            .map { String(formatted[$0.range].characters) }
            .joined()
    }

    static func configuration(for trigger: UIAlarmTrigger?) -> (amount: Int, period: ReminderPeriod) {
        guard case .relative(let offset, .start) = trigger,
              offset < 0,
              offset.isFinite
        else {
            return (5, .minutes)
        }

        let seconds = abs(offset)
        for period in [ReminderPeriod.days, .hours, .minutes] {
            let count = seconds / period.seconds
            if count.rounded() == count, (1 ... 999).contains(count) {
                return (Int(count), period)
            }
        }
        return (5, .minutes)
    }
}

#Preview {
    NavigationStack {
        AddReminderView(alarm: .preview) { _ in }
    }
}
