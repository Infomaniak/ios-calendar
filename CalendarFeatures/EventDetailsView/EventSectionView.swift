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

import CalendarCoreUI
import CalendarResources
import SwiftUI

struct EventSectionView: View {
    let event: CalendarCoreUI.UIEvent

    private let title: String
    private let location: String?
    private let isAllDay: Bool
    private let startDate: Date
    private let endDate: Date

    @Binding private var color: Color
    @Binding private var calendarColor: Color

    @Binding private var isColorPickerPresented: Bool

    init(
        event: CalendarCoreUI.UIEvent,
        color: Binding<Color> = .constant(.gray),
        calendarColor: Binding<Color> = .constant(.gray),
        isColorPickerPresented: Binding<Bool>
    ) {
        self.event = event
        title = event.title
        location = event.location
        isAllDay = event.isAllDay
        startDate = event.startDate
        endDate = event.endDate
        _color = color
        _calendarColor = calendarColor
        _isColorPickerPresented = isColorPickerPresented
    }

    private var displayedComponents: DatePickerComponents {
        if isAllDay {
            return [.date]
        } else {
            return [.date, .hourAndMinute]
        }
    }

    var body: some View {
        HStack {
            Button {
                isColorPickerPresented = true
            } label: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 0)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(calendarColor, lineWidth: 3)
                            .frame(width: 28, height: 28)
                    }
                    .padding(.trailing, 8)
            }

            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title2)
                .fontWeight(.semibold)
        }

        Section {
            Toggle(CalendarResourcesStrings.allDayLabel, isOn: .constant(isAllDay))
                .disabled(true)
            DatePicker("Start Date", selection: .constant(startDate), displayedComponents: displayedComponents)
                .disabled(true)
            DatePicker("End Date", selection: .constant(endDate), displayedComponents: displayedComponents)
                .disabled(true)
            if let location = location, !location.isEmpty {
                LabeledContent(CalendarResourcesStrings.locationOrRoomLabel, value: location)
            }
        } header: {
            Text("Date & Location")
        }
    }
}

#Preview {
    EventSectionView(
        event: UIEvent.preview,
        color: .constant(.blue),
        calendarColor: .constant(.green),
        isColorPickerPresented: .constant(false)
    )
}
