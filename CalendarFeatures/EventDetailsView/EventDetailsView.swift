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
import DesignSystem
import ESDSFoundation
import SwiftUI

public struct EventDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    private let event: CalendarCoreUI.UIEvent
    @State private var color: Color
    @State private var calendarColor: Color
    @State private var isColorPickerPresented = false
    @State private var alarms: [UIEventAlarm]
    @State private var selectedStatus: UIParticipationStatus?

    private var uniqueAttendees: [UIAttendee] {
        var seenEmails = Set<String>()

        return event.attendees.filter { attendee in
            seenEmails.insert(normalizedEmail(attendee.email)).inserted
        }
    }

    private func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var displayedComponents: DatePickerComponents {
        if event.isAllDay {
            return [.date]
        } else {
            return [.date, .hourAndMinute]
        }
    }

    public init(
        event: CalendarCoreUI.UIEvent
    ) {
        self.event = event
        _color = State(initialValue: Color(event.colors.onContainerColor))
        _calendarColor = State(initialValue: Color(.gray))
        _alarms = State(initialValue: event.alarms)
        _selectedStatus = State(initialValue: event.user?.status)
    }

    public var body: some View {
        NavigationStack {
            Form {
                EventTitleRow(
                    title: event.title,
                    calendarColor: event.colors.calendarSourceColor
                )

                if let classification = event.classification {
                    Section {
                        StatusRow(
                            text: classification == .private ? CalendarResourcesStrings.privateLabel :
                                CalendarResourcesStrings.publicLabel,
                            icon: classification == .private ? CalendarResourcesAsset.Images.lock.swiftUIImage :
                                CalendarResourcesAsset.Images.lockOpen.swiftUIImage
                        )
                    }
                }

                Section {
                    Toggle(CalendarResourcesStrings.allDayLabel, isOn: .constant(event.isAllDay))
                        .disabled(true)
                    DatePicker("Start Date", selection: .constant(event.startDate), displayedComponents: displayedComponents)
                        .disabled(true)
                    DatePicker("End Date", selection: .constant(event.endDate), displayedComponents: displayedComponents)
                        .disabled(true)
                    if let location = event.location, !location.isEmpty {
                        LabeledContent(CalendarResourcesStrings.locationOrRoomLabel, value: location)
                    }
                } header: {
                    Text("Date & Location")
                }

                CalendarSectionView(event: event, calendarColor: $calendarColor)

                if !alarms.isEmpty {
                    Section {
                        AlertsSectionView(alarms: $alarms)
                    } header: {
                        Text("Alerts")
                    }
                }
                ParticipantsSectionView(uniqueAttendees: uniqueAttendees)

                if selectedStatus != nil {
                    Section {
                        HStack(spacing: IKPadding.medium) {
                            ForEach([UIParticipationStatus.accepted, .declined, .tentative], id: \.self) { answer in
                                AnswerButton(
                                    answer: answer,
                                    isSelected: selectedStatus == answer
                                ) {
                                    selectedStatus = answer
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .closeToolbarItem(dismiss: dismiss)
            .navigationTitle(CalendarResourcesStrings.eventTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    EventDetailsView(event: CalendarCoreUI.UIEvent.preview)
}
