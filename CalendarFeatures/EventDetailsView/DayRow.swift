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

public struct DayRow: View {
    @Environment(\.esdsTheme) private var theme
    @Environment(\.calendar) private var calendar

    let event: CalendarCoreUI.UIEvent

    private var isMultiDay: Bool {
        return !calendar.isDate(event.timing.start, inSameDayAs: event.timing.end)
    }

    private var startDate: Date {
        isMultiDay ? event.timing.start : event.startDate
    }

    private var endDate: Date {
        isMultiDay ? event.timing.end : event.endDate
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text(eventDateRange)
                .font(.body)
                .foregroundStyle(theme.color.contentPrimary)

            if let eventTimeZoneRange {
                Text(eventTimeZoneRange)
                    .font(.subheadline)
                    .foregroundStyle(theme.color.contentSecondary)
            }

            // TODO: Show event recurrence information when available
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var eventDateRange: String {
        if event.isAllDay {
            let date = event.startDate.formatted(
                .dateTime
                    .weekday(.wide)
                    .month(.wide)
                    .day()
            )

            return "\(date) - \(CalendarResourcesStrings.allDayLabel)"
        }

        return dateTimeRange(in: calendar.timeZone)
    }

    private var eventTimeZoneRange: String? {
        guard
            !event.isAllDay,
            let startTimeZone = event.timing.startTimeZone,
            let endTimeZone = event.timing.endTimeZone,
            startTimeZone.secondsFromGMT() != calendar.timeZone.secondsFromGMT() ||
            endTimeZone.secondsFromGMT() != calendar.timeZone.secondsFromGMT()
        else {
            return nil
        }

        if startTimeZone.secondsFromGMT() == endTimeZone.secondsFromGMT() {
            let range = formattedRange(in: startTimeZone, includesDate: isMultiDay)
            let timeZone = formattedTimeZone(for: startDate, in: startTimeZone)

            return "\(range) (\(timeZone))"
        }

        let start = formattedDateTime(startDate, in: startTimeZone, includesDate: isMultiDay)
        let end = formattedDateTime(endDate, in: endTimeZone, includesDate: isMultiDay)

        return "\(start) - \(end)"
    }

    private func dateTimeRange(in timeZone: TimeZone) -> String {
        var style = Date.IntervalFormatStyle()
            .weekday(.wide)
            .month(.wide)
            .day()
            .hour()
            .minute()
        style.timeZone = timeZone

        return (startDate ..< endDate)
            .formatted(style)
    }

    private func formattedRange(
        in timeZone: TimeZone,
        includesDate: Bool
    ) -> String {
        let style = Date.IntervalFormatStyle(
            date: includesDate ? .abbreviated : .omitted,
            time: .shortened,
            locale: .current,
            timeZone: timeZone
        )

        return (startDate ..< endDate)
            .formatted(style)
    }

    private func formattedDateTime(
        _ date: Date,
        in timeZone: TimeZone,
        includesDate: Bool
    ) -> String {
        let dateTime =
            date.formatted(
                Date.FormatStyle(
                    date: includesDate ? .abbreviated : .omitted,
                    time: .shortened,
                    locale: .current,
                    timeZone: timeZone
                )
            )

        let timeZone = formattedTimeZone(for: date, in: timeZone)

        return "\(dateTime) (\(timeZone))"
    }

    private func formattedTimeZone(
        for date: Date,
        in timeZone: TimeZone
    ) -> String {
        date.formatted(
            Date.FormatStyle(
                date: .omitted,
                time: .omitted,
                locale: .current,
                timeZone: timeZone
            )
            .timeZone(.localizedGMT(.short))
        )
    }
}
