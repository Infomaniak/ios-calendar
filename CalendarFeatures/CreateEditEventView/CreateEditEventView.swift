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
import CoreLocationUI
import DesignSystem
import InfomaniakDI
@preconcurrency import MultiplatformCalendar
import SwiftUI

public struct CreateEditEventView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var color: Color
    @State private var calendarColor: Color
    @State private var isColorPickerPresented = false
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location: String?
    @State private var isAllDay: Bool
    @State private var selectedCalendar: UICalendar?
    @State private var availableCalendars: [UICalendar] = []

    let event: CalendarCoreUI.UIEvent?

    private var isCreateView: Bool {
        return event == nil
    }

    private var navigationTitle: String {
        return isCreateView ? "Create Event" : "Edit Event"
    }

    public init(event: CalendarCoreUI.UIEvent? = nil) {
        self.event = event
        _title = State(initialValue: event?.title ?? "")
        _startDate = State(initialValue: event?.startDate ?? Date() + 1800)
        _endDate = State(initialValue: event?.endDate ?? Date() + 3600)
        _location = State(initialValue: event?.location ?? nil)
        _isAllDay = State(initialValue: event?.isAllDay ?? false)
        _color = State(initialValue: event?.colors.onDatavizContainer ?? .gray)
        _calendarColor = State(initialValue: Color(.gray))
    }

    public var body: some View {
        Form {
            EventSectionView(
                event: event,
                isEditableView: true,
                title: $title,
                location: $location,
                isAllDay: $isAllDay,
                startDate: $startDate,
                endDate: $endDate,
                color: $color,
                calendarColor: $calendarColor,
                isColorPickerPresented: $isColorPickerPresented
            )

            CalendarSectionView(
                event: event,
                isEditableView: true,
                color: $color,
                calendarColor: $calendarColor,
                selectedCalendar: $selectedCalendar,
                availableCalendars: $availableCalendars
            )

            AlertsSectionView(event: event, isEditableView: true)

            ParticipantsSectionView(event: event)
        }
        .sheet(isPresented: $isColorPickerPresented) {
            ColorSelectionView(selection: $color)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCreateView {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close, action: dismiss.callAsFunction)
                    } else {
                        Button(action: dismiss.callAsFunction) {
                            Label("close", systemImage: "xmark")
                        }
                    }
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                if let validCalendarId = selectedCalendar?.id {
                    let timing = EventTiming(
                        start: startDate.kotlinDate,
                        end: endDate.kotlinDate,
                        startTimeZone: Kotlinx_datetimeTimeZone.companion.currentSystemDefault(),
                        endTimeZone: Kotlinx_datetimeTimeZone.companion.currentSystemDefault(),
                        isAllDay: isAllDay
                    )

                    let data = EventEditData(
                        title: title,
                        timing: timing,
                        location: location ?? "",
                        description: "",
                        calendarId: validCalendarId,
                        eventColor: color.argb,
                        alarms: []
                    )

                    if isCreateView {
                        Button("Create") {
                            register(data: data)
                        }
                    } else {
                        Button("Save") {
                            save(data: data)
                        }
                    }
                }
            }
        }
    }

    private func save(data: EventEditData) {
        guard let existingEvent = event else { return }
        Task {
            do {
                @InjectService var calendarSDK: CalendarCoreGraph
                try await calendarSDK.calendarManager.updateEvent(
                    eventId: existingEvent.sourceEventId, data: data
                )
                dismiss()
            } catch {
                print("Error saving event: \(error)")
            }
        }
    }

    private func register(data: EventEditData) {
        Task {
            do {
                @InjectService var calendarSDK: CalendarCoreGraph
                try await calendarSDK.calendarManager.createEvent(data: data)
                dismiss()
            } catch {
                print("Error create event: \(error)")
            }
        }
    }
}

#Preview {
    // Edit Event Preview
    CreateEditEventView(event: UIEvent.alarmsPreview)
}
