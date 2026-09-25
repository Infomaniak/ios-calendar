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

import CalendarResources
import DesignSystem
import ESDSFoundation
import ESDSSymbols
import SwiftUI

struct ExpandableDatePicker<ID: Hashable>: View {
    private enum ExpandedComponent {
        case date
        case hour
    }

    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    @State private var expandedComponent: ExpandedComponent?

    @Binding var date: Date
    @Binding var expandedPickerId: ID?
    @Binding var timeZonePickerId: ID?

    let timeZone: TimeZone
    let id: ID
    let label: String
    let canSelectHour: Bool
    var range: ClosedRange<Date> = Date.distantPast ... Date.distantFuture

    private var dateFormatStyle: Date.FormatStyle {
        Date.FormatStyle(timeZone: timeZone).year().month().day()
    }

    private var timeFormatStyle: Date.FormatStyle {
        let style = Date.FormatStyle(timeZone: timeZone).hour().minute()
        if timeZone.secondsFromGMT(for: date) != calendar.timeZone.secondsFromGMT(for: date) {
            return style.timeZone()
        }
        return style
    }

    var body: some View {
        Group {
            LabeledContent(label) {
                HStack {
                    Button { toggleExpansion(.date) } label: {
                        Text(date, format: dateFormatStyle)
                    }
                    .accessibilityLabel(Text(CalendarResourcesStrings.selectDateLabel))
                    .tint(expandedComponent == .date ? .accentColor : .secondary)

                    if canSelectHour {
                        Button { toggleExpansion(.hour) } label: {
                            Text(date, format: timeFormatStyle)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.default, value: date)
                        }
                        .accessibilityLabel(Text(CalendarResourcesStrings.selectTimeLabel))
                        .tint(expandedComponent == .hour ? .accentColor : .secondary)
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.primary)
            }
            .onChange(of: canSelectHour) { _, newValue in
                if !newValue, expandedComponent == .hour {
                    collapse()
                }
            }
            .onChange(of: expandedPickerId) { _, newValue in
                if newValue != id {
                    expandedComponent = nil
                }
            }

            if expandedPickerId == id, expandedComponent == .date {
                DatePicker(CalendarResourcesStrings.selectDateLabel, selection: $date, in: range, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            }

            if expandedPickerId == id, expandedComponent == .hour {
                DatePicker(
                    CalendarResourcesStrings.selectTimeLabel,
                    selection: $date,
                    in: range,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button {
                    timeZonePickerId = id
                } label: {
                    HStack(spacing: IKPadding.micro) {
                        Label(CalendarResourcesStrings.timeZoneLabel, symbol: ESDSSymbols.globe)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .labelStyle(.formLabel)

                        Text(timeZone, format: .timeZone(.displayName))
                            .foregroundStyle(theme.color.contentTertiary)

                        ESDSSymbols.chevronRight.image
                            .iconSize(IKIconSize.large)
                            .foregroundStyle(theme.color.contentTertiary)
                    }
                }
            }
        }
        .environment(\.timeZone, timeZone)
    }

    private func toggleExpansion(_ newComponent: ExpandedComponent) {
        if expandedPickerId == id, expandedComponent == newComponent {
            collapse()
        } else {
            expandedComponent = newComponent
            expandedPickerId = id
        }
    }

    private func collapse() {
        expandedComponent = nil
        if expandedPickerId == id {
            expandedPickerId = nil
        }
    }
}

#Preview {
    @Previewable @State var date = Date.now
    @Previewable @State var timeZone = TimeZone.current
    @Previewable @State var expandedPickerId: String?
    @Previewable @State var timeZonePickerId: String?

    ExpandableDatePicker(
        date: $date,
        expandedPickerId: $expandedPickerId,
        timeZonePickerId: $timeZonePickerId,
        timeZone: timeZone,
        id: "dateAndTime",
        label: "Date and time",
        canSelectHour: true
    )
    ExpandableDatePicker(
        date: $date,
        expandedPickerId: $expandedPickerId,
        timeZonePickerId: $timeZonePickerId,
        timeZone: timeZone,
        id: "date",
        label: "Date",
        canSelectHour: false
    )
}
