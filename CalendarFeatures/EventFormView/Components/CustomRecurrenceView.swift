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
import SwiftUI

struct CustomRecurrenceView: View {
    private enum EndKind: CaseIterable {
        case never
        case count
        case until

        var label: String {
            switch self {
            case .never: CalendarResourcesStrings.recurrenceEndNever
            case .count: CalendarResourcesStrings.recurrenceEndAfter
            case .until: CalendarResourcesStrings.recurrenceEndUntil
            }
        }
    }

    private static let compactRowInsets = EdgeInsets(top: 0, leading: IKPadding.medium, bottom: 0, trailing: IKPadding.medium)

    @Environment(\.dismiss) private var dismiss

    @State private var recurrence: CustomRecurrence
    @State private var recurrenceDescription: String?

    let startDate: Date
    let calendar: Calendar
    let describe: @MainActor (CustomRecurrence) async -> String?
    let onConfirm: (CustomRecurrence) -> Void

    init(
        recurrence: CustomRecurrence,
        startDate: Date,
        calendar: Calendar,
        describe: @escaping @MainActor (CustomRecurrence) async -> String?,
        onConfirm: @escaping (CustomRecurrence) -> Void
    ) {
        _recurrence = State(initialValue: recurrence)
        self.startDate = startDate
        self.calendar = calendar
        self.describe = describe
        self.onConfirm = onConfirm
    }

    private var endKind: Binding<EndKind> {
        Binding {
            switch recurrence.end {
            case .never: .never
            case .count: .count
            case .until: .until
            }
        } set: { kind in
            switch kind {
            case .never: recurrence.end = .never
            case .count: recurrence.end = .count(1)
            case .until: recurrence.end = .until(calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate)
            }
        }
    }

    private var endCount: Binding<Int> {
        Binding {
            if case .count(let count) = recurrence.end { count } else { 1 }
        } set: {
            recurrence.end = .count($0)
        }
    }

    private var endDate: Binding<Date> {
        Binding {
            if case .until(let date) = recurrence.end { date } else { startDate }
        } set: {
            recurrence.end = .until($0)
        }
    }

    var body: some View {
        Form {
            Section {
                Picker(CalendarResourcesStrings.recurrenceFrequency, selection: $recurrence.frequency) {
                    ForEach(CustomRecurrence.Frequency.allCases, id: \.self) { frequency in
                        Text(frequency.label)
                            .tag(frequency)
                    }
                }
                .pickerStyle(.menu)

                HStack(spacing: 0) {
                    Picker(CalendarResourcesStrings.recurrenceLabel, selection: $recurrence.interval) {
                        ForEach(CustomRecurrence.intervalRange, id: \.self) { interval in
                            Text(interval, format: .number.grouping(.never))
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    Text(recurrence.frequency.unitLabel(recurrence.interval))
                        .frame(maxWidth: .infinity)
                }
                .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                .listRowInsets(Self.compactRowInsets)

                switch recurrence.frequency {
                case .daily:
                    EmptyView()
                case .weekly:
                    WeekdaysPicker(weekdays: $recurrence.weekdays)
                case .monthly, .yearly:
                    Picker(CalendarResourcesStrings.recurrenceLabel, selection: $recurrence.monthDayPattern) {
                        ForEach(CustomRecurrence.MonthDayPattern.allCases, id: \.self) { pattern in
                            Text(pattern.label(frequency: recurrence.frequency, startDate: startDate, calendar: calendar))
                                .tag(pattern)
                        }
                    }
                    .pickerStyle(.menu)
                }
            } footer: {
                if let recurrenceDescription {
                    Text(recurrenceDescription)
                }
            }

            Section {
                Picker(CalendarResourcesStrings.recurrenceEnd, selection: endKind) {
                    ForEach(EndKind.allCases, id: \.self) { kind in
                        Text(kind.label)
                            .tag(kind)
                    }
                }
                .pickerStyle(.menu)

                switch recurrence.end {
                case .never:
                    EmptyView()
                case .count:
                    HStack(spacing: 0) {
                        Picker(CalendarResourcesStrings.recurrenceEndAfter, selection: endCount) {
                            ForEach(CustomRecurrence.intervalRange, id: \.self) { count in
                                Text(count, format: .number.grouping(.never))
                                    .tag(count)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)

                        Text(CalendarResourcesStrings.recurrenceEndOccurrences)
                            .frame(maxWidth: .infinity)
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .listRowInsets(Self.compactRowInsets)
                case .until:
                    DatePicker(
                        CalendarResourcesStrings.recurrenceEndUntil,
                        selection: endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .environment(\.calendar, calendar)
                    .listRowInsets(Self.compactRowInsets)
                }
            }
        }
        .navigationTitle(CalendarResourcesStrings.recurrenceCustom)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            CloseToolbarItem(action: dismiss.callAsFunction)

            ToolbarItem(placement: .confirmationAction) {
                ConfirmationButton {
                    onConfirm(recurrence)
                    dismiss()
                }
            }
        }
        .task(id: recurrence) {
            recurrenceDescription = await describe(recurrence)
        }
    }
}

#Preview {
    NavigationStack {
        CustomRecurrenceView(
            recurrence: CustomRecurrence(frequency: .monthly, startDate: .now, calendar: .current),
            startDate: .now,
            calendar: .current
        ) { _ in nil } onConfirm: { _ in }
    }
}
