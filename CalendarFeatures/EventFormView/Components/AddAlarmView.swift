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

struct AddAlarmView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var amount: Int
    @State private var period: Duration.UnitsFormatStyle.Unit
    @State private var action: UIAlarmAction

    let alarm: EventAlarmDraft
    let onAdd: (EventAlarmDraft) -> Void

    init(alarm: EventAlarmDraft, onAdd: @escaping (EventAlarmDraft) -> Void) {
        let configuration = Self.configuration(for: alarm.trigger)
        _amount = State(initialValue: configuration.amount)
        _period = State(initialValue: configuration.period)
        _action = State(initialValue: alarm.action)
        self.alarm = alarm
        self.onAdd = onAdd
    }

    var body: some View {
        Form {
            Section {
                LabeledContent(CalendarResourcesStrings.reminderTitle) {
                    Text(durationFor(amount: amount), format: .units(allowed: [period], width: .wide))
                }

                HStack {
                    Picker(CalendarResourcesStrings.otherReminderNumberLabel, selection: $amount) {
                        ForEach(period.amountRange, id: \.self) { value in
                            Text(value, format: .number)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)

                    Picker(CalendarResourcesStrings.otherReminderPeriodLabel, selection: $period) {
                        ForEach([Duration.UnitsFormatStyle.Unit.minutes, .hours, .days], id: \.self) { option in
                            Text(unitLabelFor(amount: amount, period: option))
                                .tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .onChange(of: period) { _, newPeriod in
                        amount = min(amount, newPeriod.amountRange.upperBound)
                    }
                }
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
                ConfirmationButton(action: onConfirm)
            }
        }
    }

    private func onConfirm() {
        let trigger = UIAlarmTrigger.relative(
            offset: -Double(amount) * period.seconds,
            relatedTo: .start
        )
        onAdd(alarm.with(trigger: trigger, action: action))
        dismiss()
    }

    private func durationFor(amount: Int) -> Duration {
        Duration.seconds(Double(amount) * period.seconds)
    }

    private func unitLabelFor(amount: Int, period: Duration.UnitsFormatStyle.Unit) -> String {
        switch period {
        case .minutes: CalendarResourcesStrings.unitMinutes(amount)
        case .hours: CalendarResourcesStrings.unitHours(amount)
        case .days: CalendarResourcesStrings.unitDays(amount)
        default: preconditionFailure("Unsupported alarm duration unit")
        }
    }

    private static func configuration(for trigger: UIAlarmTrigger?) -> (amount: Int, period: Duration.UnitsFormatStyle.Unit) {
        guard case .relative(let offset, .start) = trigger,
              offset < 0,
              offset.isFinite
        else {
            return (5, .minutes)
        }

        let seconds = abs(offset)
        for period in [Duration.UnitsFormatStyle.Unit.days, .hours, .minutes] {
            let count = seconds / period.seconds
            if count.rounded() == count,
               count >= Double(period.amountRange.lowerBound),
               count <= Double(period.amountRange.upperBound) {
                return (Int(count), period)
            }
        }
        return (5, .minutes)
    }
}

private extension Duration.UnitsFormatStyle.Unit {
    var seconds: TimeInterval {
        switch self {
        case .minutes: 60
        case .hours: 3600
        case .days: 86400
        default: preconditionFailure("Unsupported alarm duration unit")
        }
    }

    var amountRange: ClosedRange<Int> {
        switch self {
        case .minutes: 1 ... 60
        case .hours: 1 ... 24
        case .days: 1 ... 999
        default: preconditionFailure("Unsupported alarm duration unit")
        }
    }
}

#Preview {
    NavigationStack {
        AddAlarmView(alarm: .preview) { _ in }
    }
}
