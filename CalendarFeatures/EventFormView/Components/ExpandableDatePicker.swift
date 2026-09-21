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
import SwiftUI

struct ExpandableDatePicker<ID: Hashable>: View {
    private enum ExpandedComponent {
        case date
        case hour
    }

    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    @State private var expandedComponent: ExpandedComponent?
    @State private var isNavigatingToTimeZoneList = false

    @Binding var date: Date
    @Binding var timeZone: TimeZone
    @Binding var expandedPickerId: ID?

    let id: ID
    let label: String
    let canSelectHour: Bool
    var range: ClosedRange<Date> = Date.distantPast ... Date.distantFuture

    private var timeFormatStyle: Date.FormatStyle {
        if timeZone.secondsFromGMT(for: date) != calendar.timeZone.secondsFromGMT(for: date) {
            return .dateTime.hour().minute().timeZone()
        }
        return .dateTime.hour().minute()
    }

    var body: some View {
        Group {
            LabeledContent(label) {
                HStack {
                    Button { toggleExpansion(.date) } label: {
                        Text(date, format: .dateTime.year().month().day())
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
                    isNavigatingToTimeZoneList = true
                } label: {
                    HStack(spacing: IKPadding.micro) {
                        Label(CalendarResourcesStrings.timeZoneLabel, image: CalendarResourcesAsset.Images.globe)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .labelStyle(.formLabel)

                        Text(timeZone, format: .timeZone(.displayName))
                            .foregroundStyle(theme.color.contentTertiary)

                        CalendarResourcesAsset.Images.chevronRight.swiftUIImage
                            .iconSize(IKIconSize.large)
                            .foregroundStyle(theme.color.contentTertiary)
                    }
                }
                .navigationDestination(isPresented: $isNavigatingToTimeZoneList) {
                    TimeZoneListView(timeZone: $timeZone, referenceDate: date)
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

    ExpandableDatePicker(
        date: $date,
        timeZone: $timeZone,
        expandedPickerId: $expandedPickerId,
        id: "dateAndTime",
        label: "Date and time",
        canSelectHour: true
    )
    ExpandableDatePicker(
        date: $date,
        timeZone: $timeZone,
        expandedPickerId: $expandedPickerId,
        id: "date",
        label: "Date",
        canSelectHour: false
    )
}
