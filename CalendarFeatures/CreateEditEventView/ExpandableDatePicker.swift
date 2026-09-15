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

import SwiftUI

struct ExpandableDatePicker: View {
    @State private var isShowingDatePicker = false
    @State private var isShowingHourPicker = false

    @Binding var date: Date

    let label: String
    let canSelectHour: Bool

    var body: some View {
        LabeledContent(label) {
            HStack {
                Button {
                    isShowingDatePicker.toggle()
                    isShowingHourPicker = false
                } label: {
                    Text(date, format: .dateTime.year().month().day())
                }
                .accessibilityLabel(Text("!Select date"))

                if canSelectHour {
                    Button {
                        isShowingHourPicker.toggle()
                        isShowingDatePicker = false
                    } label: {
                        Text(date, format: .dateTime.hour().minute())
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.default, value: date)
                    }
                    .accessibilityLabel(Text("!Select hour"))
                }
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.primary)
        }

        if isShowingDatePicker {
            DatePicker("!Select date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
        }

        if isShowingHourPicker {
            DatePicker("!Select hour", selection: $date, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
        }
    }
}

#Preview {
    @Previewable @State var date = Date.now
    ExpandableDatePicker(date: $date, label: "Date and time", canSelectHour: true)
    ExpandableDatePicker(date: $date, label: "Date", canSelectHour: false)
}
