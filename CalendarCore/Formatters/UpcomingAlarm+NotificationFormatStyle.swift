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
import Foundation
import MultiplatformCalendar

public extension UpcomingAlarm {
    struct NotificationTitleFormatStyle: FormatStyle, Sendable {
        public init() {}

        public func format(_ upcomingAlarm: UpcomingAlarm) -> String {
            let title = upcomingAlarm.event.title.trimmingCharacters(in: .whitespacesAndNewlines)
            return title.isEmpty ? CalendarResourcesStrings.eventUntitledLabel : title
        }
    }

    struct NotificationBodyFormatStyle: FormatStyle, Sendable {
        private static let separator = " · "

        public init() {}

        public func format(_ upcomingAlarm: UpcomingAlarm) -> String {
            let event = upcomingAlarm.event

            let notificationFiresAt = upcomingAlarm.firesAt.toNSDate()

            let start = event.timing.startInstantLocal().toNSDate()
            let end = event.timing.endInstantLocal().toNSDate()

            var components = [String]()
            if event.timing.isAllDay {
                components.append(formatDay(start, relativeTo: notificationFiresAt))
                components.append(CalendarResourcesStrings.allDayLabel)
            } else {
                let isSingleDayEvent = Calendar.current.isDate(start, inSameDayAs: end.addingTimeInterval(-1))
                let isEventToday = Calendar.current.isDate(start, inSameDayAs: notificationFiresAt)
                if isSingleDayEvent && !isEventToday {
                    components.append(formatDay(start, relativeTo: notificationFiresAt))
                }

                components.append(formatTimeBounds(start: start, end: end))
            }

            let dateLine = components.joined(separator: Self.separator)

            if let location = event.location {
                return "\(dateLine)\n\(location)"
            }
            return dateLine
        }

        private func formatTimeBounds(start: Date, end: Date) -> String {
            return (start ..< max(start, end)).formatted(.interval.hour().minute())
        }

        private func formatDay(_ date: Date, relativeTo referenceDate: Date) -> String {
            let startOfDay = Calendar.current.startOfDay(for: date)
            let startOfReferenceDay = Calendar.current.startOfDay(for: referenceDate)
            let dayOffset = Calendar.current.dateComponents([.day], from: startOfReferenceDay, to: startOfDay).day ?? 0

            guard abs(dayOffset) <= 1 else {
                return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
            }

            var style = Date.AnchoredRelativeFormatStyle(
                anchor: startOfDay,
                presentation: .named,
                unitsStyle: .wide,
                capitalizationContext: .beginningOfSentence
            )
            style.allowedFields = [.day]
            return style.format(startOfReferenceDay)
        }
    }

    func formatted<Style: FormatStyle>(_ style: Style) -> Style.FormatOutput where Style.FormatInput == UpcomingAlarm {
        style.format(self)
    }
}

public extension FormatStyle where Self == UpcomingAlarm.NotificationTitleFormatStyle {
    static var notificationTitle: UpcomingAlarm.NotificationTitleFormatStyle {
        UpcomingAlarm.NotificationTitleFormatStyle()
    }
}

public extension FormatStyle where Self == UpcomingAlarm.NotificationBodyFormatStyle {
    static var notificationBody: UpcomingAlarm.NotificationBodyFormatStyle {
        UpcomingAlarm.NotificationBodyFormatStyle()
    }
}
