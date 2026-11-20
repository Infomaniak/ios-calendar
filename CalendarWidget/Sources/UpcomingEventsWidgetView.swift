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

import CalendarCore
import CalendarCoreUI
import CalendarResources
import DesignSystem
import ESDSCalendar
import ESDSFoundation
import ESDSSymbols
import SwiftUI
import WidgetKit

private struct EventsLayout: Hashable {
    let count: Int
    let showsLocation: Bool
}

private struct UpcomingEventCell: View {
    let event: UIEventSummary
    let showsLocation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(event.displayTitle)
                .font(.caption2.weight(.emphasized))

            if !event.isAllDay {
                Text(event.startDate ..< event.endDate, format: .eventTimeBounds)
                    .font(.caption2)
            }

            if showsLocation, let location = event.location {
                Text(location)
                    .font(.caption2)
            }
        }
        .padding(.vertical, IKPadding.micro)
        .padding(.trailing, IKPadding.mini)
        .eventCellStyle(event: event, cornerRadius: 4)
    }
}

struct UpcomingEventsWidgetView: View {
    private static let maxVisibleEvents = 4

    @Environment(\.esdsTheme) private var theme

    let entry: UpcomingEventsWidgetEntry

    /// Candidate layouts ordered by preference: as many events as possible, then a single event with its location.
    private var layouts: [EventsLayout] {
        let singleEventLayouts = [EventsLayout(count: 1, showsLocation: true), EventsLayout(count: 1, showsLocation: false)]
        let maxCount = min(entry.events.count, Self.maxVisibleEvents)
        guard maxCount > 1 else { return singleEventLayouts }

        return (2 ... maxCount).reversed().map { EventsLayout(count: $0, showsLocation: false) } + singleEventLayouts
    }

    var body: some View {
        VStack(alignment: .leading, spacing: IKPadding.micro) {
            HStack(alignment: .top, spacing: IKPadding.micro) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(.currentDate, format: .dateTime.weekday(.wide))
                        .textCase(.uppercase)
                        .font(.caption2.weight(.emphasized))
                        .foregroundStyle(theme.color.contentBrand)

                    Text(.currentDate, format: .dateTime.day())
                        .font(.title2)
                        .foregroundStyle(theme.color.contentPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Link(destination: DeeplinkConstants.newEventURL) {
                    ESDSSymbols.plus.image
                        .font(.system(size: IKIconSize.medium.rawValue, weight: .semibold))
                        .foregroundStyle(theme.color.contentOnBrand)
                        .padding(value: .small)
                        .background(theme.color.backgroundBrand, in: .circle)
                }
                .accessibilityLabel(CalendarResourcesStrings.contentDescriptionCreateEvent)
            }

            if entry.events.isEmpty {
                Text(CalendarResourcesStrings.planningNothingPlanned)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.color.contentSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ViewThatFits(in: .vertical) {
                    ForEach(layouts, id: \.self) { layout in
                        VStack(spacing: IKPadding.micro) {
                            ForEach(entry.events.prefix(layout.count)) { event in
                                Link(destination: DeeplinkConstants.eventURL(occurrenceId: event.occurrenceId)) {
                                    UpcomingEventCell(event: event, showsLocation: layout.showsLocation)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.calendar, entry.calendar)
        .environment(\.timeZone, entry.calendar.timeZone)
        .containerBackground(for: .widget) {
            theme.color.backgroundElevationSurface
        }
    }
}

#Preview(as: .systemSmall) {
    UpcomingEventsWidget()
} timeline: {
    UpcomingEventsWidgetEntry(date: .now, calendar: .current, events: [.shortPreview, .mediumPreview, .longPreview, .preview])
    UpcomingEventsWidgetEntry(date: .now, calendar: .current, events: [.mediumPreview, .preview])
    UpcomingEventsWidgetEntry(date: .now, calendar: .current, events: [.mediumPreview])
    UpcomingEventsWidgetEntry(date: .now, calendar: .current, events: [.preview])
    UpcomingEventsWidgetEntry(date: .now, calendar: .current, events: [])
}
