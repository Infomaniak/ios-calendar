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
        _alarms = State(initialValue: event.alarms)
        _selectedStatus = State(initialValue: event.user?.status)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: IKPadding.small) {
                        EventTitleRow(
                            title: event.title,
                            calendarColor: event.colors.calendarSourceColor
                        )

                        DayRow(event: event)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    ParticipantsSectionView(uniqueAttendees: uniqueAttendees)
                }

                Section {
                    if let kMeetLinkString = event.kMeetLink,
                       let kMeetLink = URL(string: kMeetLinkString) {
                        OpenLinkRow(
                            title: CalendarResourcesStrings.participateKMeetTitle,
                            buttonTitle: CalendarResourcesStrings.buttonJoin,
                            icon: CalendarResourcesAsset.Images.productKmeet.swiftUIImage,
                            linkURL: kMeetLink,
                            showLink: false
                        )
                    }

                    if let address = event.location {
                        LocationRow(address: address)
                    }

                    MeetingRoomView(roomTitle: "Salle Jules Verne", roomFloor: 3, roomCapacity: 20)
                }

                Section {
                    // TODO: Use actual event link when available
                    OpenLinkRow(
                        title: CalendarResourcesStrings.urlLinkTitle,
                        buttonTitle: CalendarResourcesStrings.openTitle,
                        icon: CalendarResourcesAsset.Images.link.swiftUIImage,
                        linkURL: URL(string: "https://www.infomaniak.com/fr")!,
                        showLink: true
                    )

                    if let description = event.description, !description.isEmpty {
                        DescriptionRow(description: description)
                    }

                    let eventFiles = [
                        "Fichetechniquedubatiment_2025.pdf",
                        "pointderdv.jpg",
                        "plan.pdf",
                        "plandureseau.json",
                        "touteslesinfos.zip",
                        "listedescontacts.xlsx"
                    ] // TODO: Replace with actual event files when available
                    ForEach(Array(eventFiles.enumerated()), id: \.offset) { fichier in
                        HStack {
                            LinkType(url: URL(string: fichier.element)!)?.icon
                            Text(fichier.element)
                        }
                    }
                }
                if !alarms.isEmpty {
                    Section {
                        AlertsSectionView(alarms: $alarms)
                    }
                }

                if let classification = event.classification {
                    Section {
                        // TODO: Add another row for free/busy status when available
                        StatusRow(
                            text: classification == .private ? CalendarResourcesStrings.privateLabel :
                                CalendarResourcesStrings.publicLabel,
                            icon: classification == .private ? CalendarResourcesAsset.Images.lock.swiftUIImage :
                                CalendarResourcesAsset.Images.lockOpen.swiftUIImage
                        )
                    }
                }

                Section {
                    EventCalendarRow(event: event)
                }
            }
            .closeToolbarItem(dismiss: dismiss)
            .navigationTitle(CalendarResourcesStrings.eventTitle)
            .navigationBarTitleDisplayMode(.inline)
            .listSectionSpacing(IKPadding.large)
            .contentMargins(.top, 0, for: .scrollContent)
            .modifier(AdaptiveSafeAreaBarModifier {
                if selectedStatus != nil {
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
                }
            })
        }
    }
}

struct AdaptiveSafeAreaBarModifier<BarContent: View>: ViewModifier {
    @ViewBuilder let barContent: () -> BarContent

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .bottom) {
                barContent()
            }
        } else {
            content.safeAreaInset(edge: .bottom) {
                barContent()
                    .padding(.top, IKPadding.medium)
                    .background(Material.bar)
            }
        }
    }
}

#Preview {
    EventDetailsView(event: CalendarCoreUI.UIEvent.preview)
}
