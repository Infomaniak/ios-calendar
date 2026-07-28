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

    init(event: CalendarCoreUI.UIEvent, color: Binding<Color> = .constant(.gray)) {
        self.event = event
        title = event.title
        location = event.location
        isAllDay = event.isAllDay
        startDate = event.startDate
        endDate = event.endDate
        _color = color
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
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 8, height: 32)
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
    EventSectionView(event: UIEvent.preview)
}
