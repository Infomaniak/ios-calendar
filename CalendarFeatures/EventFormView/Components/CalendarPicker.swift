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

struct CalendarPicker: View {
    @Binding var calendarId: String?

    let sections: [UICalendarSection]
    let selectedCalendar: UICalendar?

    private var hasSeveralCalendars: Bool {
        sections.count > 1 || sections.first?.calendars.count ?? 0 > 1
    }

    var body: some View {
        Menu {
            if sections.count > 1 {
                ForEach(sections) { section in
                    Section(section.organisationName ?? CalendarResourcesStrings.otherCalendarsSectionTitle) {
                        buttons(forCalendars: section.calendars)
                    }
                }
            } else if let section = sections.first {
                buttons(forCalendars: section.calendars)
            }
        } label: {
            if let selectedCalendar {
                HStack {
                    CalendarLabel(calendar: selectedCalendar)

                    if hasSeveralCalendars {
                        Image(systemName: "chevron.up.chevron.down")
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!hasSeveralCalendars)
    }

    private func buttons(forCalendars calendars: [CalendarCoreUI.UICalendar]) -> some View {
        ForEach(calendars) { calendar in
            Button {
                calendarId = calendar.id
            } label: {
                CalendarLabel(calendar: calendar)
            }
        }
    }
}

#Preview {
    CalendarPicker(calendarId: .constant(UICalendar.preview.id), sections: [.preview], selectedCalendar: nil)
}
