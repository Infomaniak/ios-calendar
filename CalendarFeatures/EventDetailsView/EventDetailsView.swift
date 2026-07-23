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
import DesignSystem
import SwiftUI

public struct EventDetailsView: View {

    private let event: CalendarCoreUI.UIEvent
    private var calendar: UICalendar?

    public init(
        event: CalendarCoreUI.UIEvent,
        calendar: UICalendar? = nil
    ) {
        self.event = event
        self.calendar = calendar
    }

    public var body: some View {
        Form {
            EventSectionView(event: event)

            CalendarSectionView(calendar: calendar, event: event)

            ParticipantsSectionView(event: event)
           
        }
    }
}

struct AttendeeRow: View {
    let attendee: UIAttendee
    let isOrganizer: Bool

    var body: some View {
        HStack(spacing: IKPadding.medium) {
            AvatarView(
                rawAvatarURL: nil,
                displayName: attendee.displayName ?? attendee.email,
                email: attendee.email,
                size: 24
            )

            VStack(alignment: .leading, spacing: IKPadding.micro) {
                HStack(spacing: IKPadding.mini) {
                    Text(attendee.displayName ?? attendee.email)

                    if isOrganizer {
                        Text("Organisateur")
                            .font(.caption2)
                            .padding(.horizontal, IKPadding.mini)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                if attendee.displayName != nil {
                    Text(attendee.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    EventDetailsView(event: CalendarCoreUI.UIEvent.preview, calendar: UICalendar.preview)
}
