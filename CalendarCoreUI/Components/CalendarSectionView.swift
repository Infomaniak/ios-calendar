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
import DesignSystem
import InfomaniakCoreSwiftUI
import InfomaniakDI
@preconcurrency import MultiplatformCalendar
import SwiftUI

public struct CalendarSectionView: View {
    @State private var selectedCalendar: UICalendar?
    @State private var availableCalendars: [UICalendar] = []
    @Binding private var color: Color
    @Binding private var calendarColor: Color

    let event: CalendarCoreUI.UIEvent?
    let isEditableView: Bool

    public init(
        event: CalendarCoreUI.UIEvent?,
        isEditableView: Bool = false,
        color: Binding<Color> = .constant(.gray),
        calendarColor: Binding<Color> = .constant(.gray)
    ) {
        self.event = event
        self.isEditableView = isEditableView
        _color = color
        _calendarColor = calendarColor
    }

    public var body: some View {
        Section {
            if isEditableView {
                HStack(spacing: 8) {
                    Picker(CalendarResourcesStrings.sectionCalendarHeader, selection: $selectedCalendar) {
                        Circle()
                            .fill(calendarColor)
                            .frame(width: 12, height: 12)
                            .accessibilityHidden(true)

                        ForEach(availableCalendars) { calendar in
                            Text(calendar.displayName)
                                .lineLimit(1)
                                .tag(UICalendar?.some(calendar))
                        }
                    }
                }
            } else {
                if let selectedCalendar {
                    LabeledContent {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(selectedCalendar.color)
                                .frame(width: 12, height: 12)
                                .accessibilityHidden(true)

                            Text(selectedCalendar.displayName)
                                .lineLimit(1)
                        }

                    } label: {
                        Text(CalendarResourcesStrings.sectionCalendarHeader)
                    }
                }
            }
        } header: {
            Text(CalendarResourcesStrings.sectionCalendarHeader)
        }
        .task {
            await observeCalendars()
        }
        .onChange(of: selectedCalendar) { _, newValue in
            color = newValue?.color ?? .gray
            calendarColor = newValue?.color ?? .gray
        }
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        var didSetInitialSelection = false

        for await calendars in calendarSDK.calendarManager.observeCalendars() {
            let uiCalendars = calendars.map { UICalendar(calendar: $0) }
            availableCalendars = uiCalendars

            if !didSetInitialSelection {
                if let event {
                    selectedCalendar = uiCalendars.first { $0.id == event.calendarId }
                }
                calendarColor = selectedCalendar?.color ?? .gray
                didSetInitialSelection = true
            }
        }
    }
}

#Preview {
    CalendarSectionView(event: UIEvent.preview)
}
