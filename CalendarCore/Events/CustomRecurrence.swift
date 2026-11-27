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

public struct CustomRecurrence: Hashable, Sendable {
    public enum Frequency: CaseIterable, Hashable, Sendable {
        case daily
        case weekly
        case monthly
        case yearly
    }

    /// Day of the month the event repeats on, relative to the event start date.
    public enum MonthDayPattern: CaseIterable, Hashable, Sendable {
        /// Same day number as the start date (e.g. every 26th).
        case dayOfMonth
        /// First occurrence of the start weekday in the month (e.g. first Thursday).
        case firstWeekday
        /// Last occurrence of the start weekday in the month (e.g. last Thursday).
        case lastWeekday
    }

    public enum End: Hashable, Sendable {
        case never
        case count(Int)
        /// Last day (inclusive) on which the event can occur.
        case until(Date)
    }

    public static let intervalRange = 1 ... 999

    public var frequency: Frequency
    public var interval: Int
    /// Weekdays used by weekly recurrences. Should never be empty.
    public var weekdays: Set<Locale.Weekday>
    /// Day pattern used by monthly and yearly recurrences.
    public var monthDayPattern: MonthDayPattern
    public var end: End

    public init(
        frequency: Frequency,
        interval: Int = 1,
        weekdays: Set<Locale.Weekday>,
        monthDayPattern: MonthDayPattern = .dayOfMonth,
        end: End = .never
    ) {
        self.frequency = frequency
        self.interval = interval
        self.weekdays = weekdays
        self.monthDayPattern = monthDayPattern
        self.end = end
    }
}

public extension CustomRecurrence {
    init(frequency: Frequency = .weekly, startDate: Date, calendar: Foundation.Calendar) {
        self.init(frequency: frequency, weekdays: [Locale.Weekday(date: startDate, calendar: calendar)])
    }

    init(recurrence: EventRecurrence, startDate: Date, calendar: Foundation.Calendar) {
        let frequency: Frequency = switch recurrence {
        case .daily: .daily
        case .monthly: .monthly
        case .yearly: .yearly
        case .none, .weekly, .custom: .weekly
        }
        self.init(frequency: frequency, startDate: startDate, calendar: calendar)
    }

    /// Best-effort mapping of an RFC 5545 rule. Parts that can't be represented are dropped.
    init(rule: RecurrenceRule, startDate: Date, calendar: Foundation.Calendar) {
        let startWeekday = Locale.Weekday(date: startDate, calendar: calendar)
        let frequency = Frequency(frequency: rule.freq)

        let ruleWeekdays = Set(rule.byDay.map { Locale.Weekday(dayOfWeek: $0.dayOfWeek) })
        let weekdays = frequency == .weekly && !ruleWeekdays.isEmpty ? ruleWeekdays : [startWeekday]

        let position = rule.byDay.first?.ordinal?.intValue ?? rule.byOccurrencePosition.first?.intValue
        let monthDayPattern: MonthDayPattern = switch position {
        case 1: .firstWeekday
        case -1: .lastWeekday
        default: .dayOfMonth
        }

        self.init(
            frequency: frequency,
            interval: Int(rule.interval).clamped(to: Self.intervalRange),
            weekdays: weekdays,
            monthDayPattern: monthDayPattern,
            end: End(rule: rule, calendar: calendar)
        )
    }

    /// Builds the minimal rule matching this recurrence, using `startDate` (DTSTART) for implicit parts.
    func sdkValue(startDate: Date, calendar: Foundation.Calendar, allDay: Bool = false) -> RecurrenceRule {
        let startWeekday = Locale.Weekday(date: startDate, calendar: calendar)
        var byDay = [WeekDayNum]()
        var byMonth = [KotlinInt]()

        switch frequency {
        case .daily:
            break
        case .weekly:
            if weekdays != [startWeekday] {
                byDay = Locale.Weekday.isoOrdered
                    .filter { weekdays.contains($0) }
                    .map { WeekDayNum(ordinal: nil, dayOfWeek: $0.dayOfWeek) }
            }
        case .monthly, .yearly:
            if let ordinal = monthDayPattern.ordinal {
                byDay = [WeekDayNum(ordinal: KotlinInt(int: ordinal), dayOfWeek: startWeekday.dayOfWeek)]
                if frequency == .yearly {
                    byMonth = [KotlinInt(int: Int32(calendar.component(.month, from: startDate)))]
                }
            }
        }

        return RecurrenceRule(
            freq: frequency.sdkValue,
            interval: Int32(interval.clamped(to: Self.intervalRange)),
            occurrenceCount: occurrenceCount,
            until: sdkUntil(calendar: calendar, allDay: allDay),
            byDay: byDay,
            byMonthDay: [],
            byMonth: byMonth,
            byOccurrencePosition: [],
            weekStart: nil,
            byHour: [],
            byMinute: [],
            bySecond: [],
            byYearDay: [],
            byWeekNumber: []
        )
    }

    private var occurrenceCount: KotlinInt? {
        guard case .count(let count) = end else { return nil }
        return KotlinInt(int: Int32(count.clamped(to: Self.intervalRange)))
    }

    private func sdkUntil(calendar: Foundation.Calendar, allDay: Bool) -> RecurrenceUntil? {
        guard case .until(let date) = end else { return nil }

        if allDay {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return RecurrenceUntilDateOnly(
                date: LocalDate(
                    year: Int32(components.year ?? 1970),
                    month: Int32(components.month ?? 1),
                    day: Int32(components.day ?? 1)
                )
            )
        }

        let endOfDay = calendar.date(byAdding: .second, value: -1, to: calendar.startOfDay(for: date).addingTimeInterval(86400))
            ?? date
        return RecurrenceUntilDateTimeUtc(instant: endOfDay.instant)
    }
}

private extension CustomRecurrence.End {
    init(rule: RecurrenceRule, calendar: Foundation.Calendar) {
        if let count = rule.occurrenceCount {
            self = .count(Int(count.int32Value).clamped(to: CustomRecurrence.intervalRange))
        } else if let dateOnly = rule.until as? RecurrenceUntilDateOnly {
            let components = DateComponents(
                year: Int(dateOnly.date.year),
                month: Int(dateOnly.date.monthNumber),
                day: Int(dateOnly.date.day)
            )
            self = calendar.date(from: components).map { .until($0) } ?? .never
        } else if let dateTime = rule.until as? RecurrenceUntilDateTimeUtc {
            self = .until(Date(timeIntervalSince1970: TimeInterval(dateTime.instant.toEpochMilliseconds()) / 1000))
        } else {
            self = .never
        }
    }
}

private extension CustomRecurrence.Frequency {
    init(frequency: MultiplatformCalendar.Frequency) {
        switch frequency {
        case .weekly: self = .weekly
        case .monthly: self = .monthly
        case .yearly: self = .yearly
        default: self = .daily
        }
    }

    var sdkValue: MultiplatformCalendar.Frequency {
        switch self {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }
}

private extension CustomRecurrence.MonthDayPattern {
    var ordinal: Int32? {
        switch self {
        case .dayOfMonth: nil
        case .firstWeekday: 1
        case .lastWeekday: -1
        }
    }
}

public extension Locale.Weekday {
    /// Weekdays indexed by `Calendar` weekday component (1 = Sunday).
    static let calendarOrdered: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    init(date: Date, calendar: Foundation.Calendar) {
        self = Self.calendarOrdered[calendar.component(.weekday, from: date) - 1]
    }
}

extension Locale.Weekday {
    static let isoOrdered: [Locale.Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    init(dayOfWeek: DayOfWeek) {
        switch dayOfWeek {
        case .monday: self = .monday
        case .tuesday: self = .tuesday
        case .wednesday: self = .wednesday
        case .thursday: self = .thursday
        case .friday: self = .friday
        case .saturday: self = .saturday
        case .sunday: self = .sunday
        }
    }

    var dayOfWeek: DayOfWeek {
        switch self {
        case .monday: .monday
        case .tuesday: .tuesday
        case .wednesday: .wednesday
        case .thursday: .thursday
        case .friday: .friday
        case .saturday: .saturday
        case .sunday: .sunday
        @unknown default: .monday
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
