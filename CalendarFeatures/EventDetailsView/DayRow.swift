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
    let event: CalendarCoreUI.UIEvent

    public var body: some View {
        HStack(spacing: IKPadding.medium) {
            CalendarResourcesAsset.Images.clock.swiftUIImage
                .iconSize(IKIconSize.large)
                .foregroundStyle(theme.color.contentSecondary)

            VStack(alignment: .leading) {
                dateRangeText
                    .font(.body)
                    .foregroundStyle(theme.color.contentPrimary)

                if let timeZoneRangeText {
                    Text(timeZoneRangeText)
                        .font(.subheadline)
                        .foregroundStyle(theme.color.contentSecondary)
                }

                Text("Chaque semaine le mercredi") // TODO: Use event recurrence
                    .font(.subheadline)
                    .foregroundStyle(theme.color.contentBrandDefault)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateRangeText: Text {
        let date = Text(event.startDate, format: .dateTime.month(.wide).day().weekday(.wide))

        let detail = event.isAllDay ? CalendarResourcesStrings.allDayLabel : timeRange(in: .current)

        return date + Text(" - \(detail)")
    }

    private var timeZoneRangeText: String? {
        guard let startTimeZone = event.startTimeZone,
              let endTimeZone = event.endTimeZone else { return nil }

        if startTimeZone == endTimeZone {
            return "\(timeRange(in: startTimeZone)) (\(formattedTimeZone(for: event.startDate, in: startTimeZone)))"
        }

        return [
            formattedTime(for: event.startDate, in: startTimeZone),
            "(\(formattedTimeZone(for: event.startDate, in: startTimeZone)))",
            "-",
            formattedTime(for: event.endDate, in: endTimeZone),
            "(\(formattedTimeZone(for: event.endDate, in: endTimeZone)))"
        ]
        .joined(separator: " ")
    }

    private func timeRange(in timeZone: TimeZone) -> String {
        (event.startDate ..< event.endDate)
            .formatted(
                Date.IntervalFormatStyle(
                    date: .omitted,
                    time: .shortened,
                    locale: .current,
                    timeZone: timeZone
                )
            )
    }

    private func formattedTime(for date: Date, in timeZone: TimeZone) -> String {
        date.formatted(
            Date.FormatStyle(
                date: .omitted,
                time: .shortened,
                locale: .current,
                timeZone: timeZone
            )
        )
    }

    private func formattedTimeZone(for date: Date, in timeZone: TimeZone) -> String {
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
