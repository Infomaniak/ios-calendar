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

public enum EventRecurrence: Hashable, Sendable {
    case none
    case daily
    case weekly
    case monthly
    case yearly
    case custom

    public static let presets: [EventRecurrence] = [.daily, .weekly, .monthly, .yearly]
}

public extension EventRecurrence {
    init(timing: EventTiming) {
        let recurrence = EventRecurrence(rule: timing.recurrenceRule)
        self = recurrence == .none && !timing.rDates.isEmpty ? .custom : recurrence
    }

    init(rule: RecurrenceRule?) {
        guard let rule else {
            self = .none
            return
        }

        guard rule.isSimple, let preset = EventRecurrence(frequency: rule.freq) else {
            self = .custom
            return
        }
        self = preset
    }

    private init?(frequency: Frequency) {
        switch frequency {
        case .daily: self = .daily
        case .weekly: self = .weekly
        case .monthly: self = .monthly
        case .yearly: self = .yearly
        default: return nil
        }
    }

    private var frequency: Frequency? {
        switch self {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        case .none, .custom: nil
        }
    }

    func sdkValue(preserving originalRule: RecurrenceRule?) -> RecurrenceRule? {
        switch self {
        case .none:
            return nil
        case .custom:
            return originalRule
        case .daily, .weekly, .monthly, .yearly:
            guard let frequency else { return nil }
            if let originalRule, EventRecurrence(rule: originalRule) == self {
                return originalRule
            }
            return RecurrenceRule(
                freq: frequency,
                interval: 1,
                occurrenceCount: nil,
                until: nil,
                byDay: [],
                byMonthDay: [],
                byMonth: [],
                byOccurrencePosition: [],
                weekStart: nil,
                byHour: [],
                byMinute: [],
                bySecond: [],
                byYearDay: [],
                byWeekNumber: []
            )
        }
    }
}

private extension RecurrenceRule {
    var isSimple: Bool {
        interval == 1
            && occurrenceCount == nil
            && until == nil
            && weekStart == nil
            && byDay.isEmpty
            && byMonthDay.isEmpty
            && byMonth.isEmpty
            && byOccurrencePosition.isEmpty
            && byHour.isEmpty
            && byMinute.isEmpty
            && bySecond.isEmpty
            && byYearDay.isEmpty
            && byWeekNumber.isEmpty
    }
}
