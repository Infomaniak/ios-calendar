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
import InfomaniakCoreSwiftUI
import InfomaniakDI
@preconcurrency import MultiplatformCalendar
import SwiftUI

struct EventCalendarRow: View {
    @Environment(\.esdsTheme) private var theme

    @State private var selectedCalendar: UICalendar?

    let event: CalendarCoreUI.UIEvent?

    init(
        event: CalendarCoreUI.UIEvent?,
    ) {
        self.event = event
    }

    var body: some View {
        VStack {
            if let selectedCalendar {
                LabeledContent {
                    HStack {
                        Circle()
                            .fill(selectedCalendar.color)
                            .frame(width: IKIconSize.small.rawValue, height: IKIconSize.small.rawValue)
                            .accessibilityHidden(true)

                        Text(selectedCalendar.displayName)
                            .lineLimit(1)
                    }
                } label: {
                    HStack {
                        CalendarResourcesAsset.Images.productCalendar.swiftUIImage
                            .iconSize(IKIconSize.large)
                            .foregroundStyle(theme.color.contentSecondary)
                        Text(CalendarResourcesStrings.sectionCalendarHeader)
                            .font(.body)
                            .foregroundStyle(theme.color.contentPrimary)
                    }
                }
            }
        }
        .task {
            await observeCalendars()
        }
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            let availableCalendars = calendars.map { UICalendar(calendar: $0) }

            if let event {
                selectedCalendar = availableCalendars.first { $0.id == event.calendarId }
            }
        }
    }
}

#Preview {
    EventCalendarRow(event: UIEvent.preview)
}
