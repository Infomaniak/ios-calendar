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

import Foundation
import MultiplatformCalendar

public extension RecurrenceRule {
    /// KMP 0.18 keeps its RFC 5545 serializer internal.
    var availabilityRRule: String {
        var fields = ["FREQ=\(freq.name.uppercased())"]
        if let until {
            let value: String
            switch onEnum(of: until) {
            case .dateOnly(let bound):
                value = dateString(bound.date)
            case .dateTimeUtc(let bound):
                let utc = Foundation.TimeZone(secondsFromGMT: 0)!.toKotlinTimeZone()
                value = dateTimeString(utc.toLocalDateTime(bound.instant)) + "Z"
            case .floating(let bound):
                value = dateTimeString(bound.dateTime)
            }
            fields.append("UNTIL=\(value)")
        }
        if let occurrenceCount {
            fields.append("COUNT=\(occurrenceCount.intValue)")
        }
        if interval != 1 {
            fields.append("INTERVAL=\(interval)")
        }
        let lists: [(String, [KotlinInt])] = [
            ("BYSECOND", bySecond), ("BYMINUTE", byMinute), ("BYHOUR", byHour),
            ("BYMONTHDAY", byMonthDay), ("BYYEARDAY", byYearDay), ("BYWEEKNO", byWeekNumber),
            ("BYMONTH", byMonth), ("BYSETPOS", byOccurrencePosition)
        ]
        for (key, values) in lists where !values.isEmpty {
            fields.append("\(key)=\(values.map { String($0.intValue) }.joined(separator: ","))")
        }
        if !byDay.isEmpty {
            let days = byDay.map { day in
                let ordinal = day.ordinal.map { String($0.intValue) } ?? ""
                return ordinal + day.dayOfWeek.name.prefix(2)
            }
            fields.append("BYDAY=\(days.joined(separator: ","))")
        }
        if let weekStart {
            fields.append("WKST=\(weekStart.name.prefix(2))")
        }
        return fields.joined(separator: ";")
    }

    private func dateString(_ date: LocalDate) -> String {
        String(format: "%04d%02d%02d", date.year, date.monthNumber, date.day)
    }

    private func dateTimeString(_ date: LocalDateTime) -> String {
        dateString(date.date) + String(format: "T%02d%02d%02d", date.hour, date.minute, date.second)
    }
}
