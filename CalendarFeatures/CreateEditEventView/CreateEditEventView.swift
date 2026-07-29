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

            Section {
                Picker("Calendar", selection: $selectedCalendar) {
                    ForEach(availableCalendars) { calendar in
                        HStack {
                            Circle()
                                .fill(calendar.color)
                                .frame(width: 8, height: 8)
                            Text(calendar.displayName)
                        }
                        .tag(UICalendar?.some(calendar))
                    }
                }

                LabeledContent("Event Color") {
                    HStack(spacing: 8) {
                        ForEach(colors, id: \.self) { paletteColor in
                            Circle()
                                .fill(paletteColor)
                                .frame(width: 16, height: 16)
                                .overlay {
                                    if paletteColor == color {
                                        Circle().stroke(.primary, lineWidth: 2).padding(-3)
                                    }
                                }
                                .onTapGesture { color = paletteColor }
                        }
                    }
                }

            } header: {
                Text("Calendar & Color")
            }

            Section {
                ForEach(alarmOffsets.indices, id: \.self) { index in
                    Picker("Alarm \(index + 1)", selection: $alarmOffsets[index]) {
                        ForEach(AlarmOffset.allCases) { offset in
                            Text(offset.rawValue).tag(offset)
                        }
                    }
                }
                .onDelete { indexSet in
                    alarmOffsets.remove(atOffsets: indexSet)
                }

                Button {
                    alarmOffsets.append(.none)
                } label: {
                    Label("Add alarm", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Alerts")
            }

            Section {
                List {
                    DisclosureGroup(isExpanded: $attendeesListIsOpen) {
                        ForEach(uniqueAttendees) { attendee in
                            HStack {
                                Text(attendee.displayName ?? attendee.email)
                                Spacer()
                            }
                        }
                    } label: {
                        HStack(spacing: IKPadding.micro) {
                            HStack(spacing: -24 / 3) {
                                ForEach(Array(visibleAttendees.enumerated()), id: \.element) { attendee in
                                    AvatarView(rawAvatarURL: nil,
                                               displayName: attendee.element.displayName ?? attendee.element.email,
                                               email: attendee.element.email,
                                               size: 24)
                                }
                            }
                            .compositingGroup()

                            Text("\(uniqueAttendees.count) Personnes participent")
                        }
                    }
                }
            } header: {
                Text("Participants")
            }
        }
        .sheet(isPresented: $isColorPickerPresented) {
            ColorSelectionView(selection: $color)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .close, action: dismiss.callAsFunction)
                } else {
                    Button(action: dismiss.callAsFunction) {
                        Label("close", systemImage: "xmark")
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
            }
        }

        .task {
            await observeCalendars()
        }
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            let uiCalendars = calendars.map { UICalendar(calendar: $0) }
            availableCalendars = uiCalendars

            if let event {
                selectedCalendar = uiCalendars.first { $0.id == event.calendarId }
            }
        }
    }

    private func save() {
        let triggerDates = alarmOffsets.compactMap { $0.triggerDate(for: startDate) }
        print("Alarms trigger dates:", triggerDates)
        dismiss()
    }
}

#Preview {
    // Edit Event Preview
    CreateEditEventView(event: UIEvent.alarmsPreview)
}
