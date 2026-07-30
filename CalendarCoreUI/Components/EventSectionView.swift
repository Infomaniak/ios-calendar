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
import SwiftUI

public struct EventSectionView: View {
    let event: CalendarCoreUI.UIEvent?
    let isEditableView: Bool

    @Binding private var title: String
    @Binding private var description: String?
    @Binding private var location: String?
    @Binding private var isAllDay: Bool
    @Binding private var startDate: Date
    @Binding private var endDate: Date

    @Binding private var color: Color
    @Binding private var calendarColor: Color

    @Binding private var isColorPickerPresented: Bool

    public init(
        event: CalendarCoreUI.UIEvent?,
        isEditableView: Bool = false,
        title: Binding<String> = .constant(""),
        description: Binding<String?> = .constant(nil),
        location: Binding<String?> = .constant(nil),
        isAllDay: Binding<Bool> = .constant(false),
        startDate: Binding<Date> = .constant(Date()),
        endDate: Binding<Date> = .constant(Date()),
        color: Binding<Color> = .constant(.gray),
        calendarColor: Binding<Color> = .constant(.gray),
        isColorPickerPresented: Binding<Bool>
    ) {
        self.event = event
        self.isEditableView = isEditableView
        _title = isEditableView ? title : .constant(event?.title ?? "")
        _description = isEditableView ? description : .constant(event?.description)
        _location = isEditableView ? location : .constant(event?.location)
        _isAllDay = isEditableView ? isAllDay : .constant(event?.isAllDay ?? false)
        _startDate = isEditableView ? startDate : .constant(event?.startDate ?? Date())
        _endDate = isEditableView ? endDate : .constant(event?.endDate ?? Date())
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

    public var body: some View {
        Section {
            HStack {
                if isEditableView {
                    Button {
                        isColorPickerPresented = true
                    } label: {
                        ColorSelectorButtonLabel(color: $color, calendarColor: $calendarColor)
                    }

                    TextField("Title", text: $title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title2)
                        .fontWeight(.semibold)
                } else {
                    ColorSelectorButtonLabel(color: $color, calendarColor: $calendarColor)

                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            if isEditableView {
                TextField(
                    "Description",
                    text: Binding(
                        get: { description ?? "" },
                        set: { description = $0 }
                    ),
                    axis: .vertical
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(1 ... 6)
                .fixedSize(horizontal: false, vertical: true)
            } else if let description, !description.isEmpty {
                Text(description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1 ... 6)
            }
        }

        Section {
            Toggle(CalendarResourcesStrings.allDayLabel, isOn: $isAllDay)
                .disabled(!isEditableView)
            DatePicker("Start Date", selection: $startDate, displayedComponents: displayedComponents)
                .disabled(!isEditableView)
            DatePicker("End Date", selection: $endDate, displayedComponents: displayedComponents)
                .disabled(!isEditableView)

            if isEditableView {
                TextField(
                    CalendarResourcesStrings.locationOrRoomLabel,
                    text: Binding(
                        get: { location ?? "" },
                        set: { location = $0 }
                    )
                )
                .textContentType(.fullStreetAddress)
            } else if let location, !location.isEmpty {
                LabeledContent(
                    CalendarResourcesStrings.locationOrRoomLabel,
                    value: location
                )
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
