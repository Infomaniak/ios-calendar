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
    @State private var colors: [Color] = [.gray, .red, .orange, .yellow, .green, .blue, .purple]
    @State private var color: Color = .gray
    @State private var calendarColor: Color
    @State private var isColorPickerPresented = false
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location: String?
    @State private var isAllDay: Bool
    @State private var selectedCalendar: UICalendar?
    @State private var availableCalendars: [UICalendar] = []
    @State private var alarmOffsets: [AlarmOffset] = []
    @State private var attendeesListIsOpen = true

    let event: CalendarCoreUI.UIEvent?

    private var uniqueAttendees: [UIAttendee] {
        guard let event = event else { return [] }
        var seenEmails = Set<String>()

        return event.attendees.filter { attendee in
            seenEmails.insert(normalizedEmail(attendee.email)).inserted
        }
    }

    private var visibleAttendees: [UIAttendee] {
        Array(uniqueAttendees.prefix(3))
    }

    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var navigationTitle: String {
        if let event = event {
            return "Edit Event: \(event.title)"
        } else {
            return "Create Event"
        }
    }

    public init(event: CalendarCoreUI.UIEvent? = nil) {
        self.event = event
        _title = State(initialValue: event?.title ?? "")
        _startDate = State(initialValue: event?.startDate ?? Date())
        _endDate = State(initialValue: event?.endDate ?? Date() + 3600)
        _location = State(initialValue: event?.location ?? nil)
        _isAllDay = State(initialValue: event?.isAllDay ?? false)
        _startDate = State(initialValue: event?.startDate ?? Date())
        _endDate = State(initialValue: event?.endDate ?? Date() + 3600)
        _color = State(initialValue: event?.colors.onDatavizContainer ?? .gray)
        _alarmOffsets = State(initialValue: (event?.alarms ?? []).map {
            AlarmOffset(trigger: $0.trigger)
        })
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

            AlertsSectionView(
                event: event,
                isEditableView: true
            )

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
            if event == nil {
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
                if event == nil {
                    Button("Create", action: register)
                } else {
                    Button("Save", action: save)
                }
            }
        }
    }

    private func save() {
        guard let existingEvent = event else { return }
        guard let validCalendarId = selectedCalendar?.id else { return }

        Task {
            let calendar = Calendar.current
            let startComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second, .nanosecond],
                from: startDate
            )
            let endComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second, .nanosecond],
                from: endDate
            )

            do {
                @InjectService var calendarSDK: CalendarCoreGraph

                try await calendarSDK.calendarManager.updateEvent(eventId: existingEvent.id, data: EventEditData(
                    title: title,
                    timing: EventTiming(
                        start: .init(
                            year: Int32(startComponents.year ?? 0),
                            month: Int32(startComponents.month ?? 0),
                            day: Int32(startComponents.day ?? 0),
                            hour: Int32(startComponents.hour ?? 0),
                            minute: Int32(startComponents.minute ?? 0),
                            second: Int32(startComponents.second ?? 0),
                            nanosecond: Int32(startComponents.nanosecond ?? 0)
                        ),
                        end: .init(
                            year: Int32(endComponents.year ?? 0),
                            month: Int32(endComponents.month ?? 0),
                            day: Int32(endComponents.day ?? 0),
                            hour: Int32(endComponents.hour ?? 0),
                            minute: Int32(endComponents.minute ?? 0),
                            second: Int32(endComponents.second ?? 0),
                            nanosecond: Int32(endComponents.nanosecond ?? 0)
                        ),
                        startTimeZone: Kotlinx_datetimeTimeZone.companion.currentSystemDefault(),
                        endTimeZone: Kotlinx_datetimeTimeZone.companion.currentSystemDefault(),
                        isAllDay: isAllDay
                    ),
                    location: location ?? "",
                    description: "",
                    calendarId: validCalendarId,
                    eventColor: color,
                    alarms: []
                ))

                dismiss()

            } catch {
                print("Error saving event: \(error)")
            }
        }
    }

    private func register() {
        guard let validCalendarId = selectedCalendar?.id else { return }

        Task {
            let calendar = Calendar.current
            let startComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second, .nanosecond],
                from: startDate
            )
            let endComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second, .nanosecond],
                from: endDate
            )

            do {
                @InjectService var calendarSDK: CalendarCoreGraph

                try await calendarSDK.calendarManager.createEvent(data: EventEditData(
                    title: title,
                    timing: EventTiming(
                        start: .init(
                            year: Int32(startComponents.year ?? 0),
                            month: Int32(startComponents.month ?? 0),
                            day: Int32(startComponents.day ?? 0),
                            hour: Int32(startComponents.hour ?? 0),
                            minute: Int32(startComponents.minute ?? 0),
                            second: Int32(startComponents.second ?? 0),
                            nanosecond: Int32(startComponents.nanosecond ?? 0)
                        ),
                        end: .init(
                            year: Int32(endComponents.year ?? 0),
                            month: Int32(endComponents.month ?? 0),
                            day: Int32(endComponents.day ?? 0),
                            hour: Int32(endComponents.hour ?? 0),
                            minute: Int32(endComponents.minute ?? 0),
                            second: Int32(endComponents.second ?? 0),
                            nanosecond: Int32(endComponents.nanosecond ?? 0)
                        ),
                        startTimeZone: Kotlinx_datetimeTimeZone.companion.currentSystemDefault(),
                        endTimeZone: Kotlinx_datetimeTimeZone.companion.currentSystemDefault(),
                        isAllDay: isAllDay
                    ),
                    location: location ?? "",
                    description: "",
                    calendarId: validCalendarId,
                    eventColor: color.argb,
                    alarms: []
                ))

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
