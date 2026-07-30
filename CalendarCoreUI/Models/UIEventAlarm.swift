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
@preconcurrency import MultiplatformCalendar

public struct UIEventAlarm: Sendable, Hashable {
    public let action: UIAlarmAction
    public let trigger: UIAlarmTrigger
    public let description: String?
    public let summary: String?
    public let attendees: [String]
    public let attachments: [String]

    public init(
        action: UIAlarmAction,
        trigger: UIAlarmTrigger,
        attachments: [String],
        attendees: [String],
        description: String?,
        summary: String?
    ) {
        self.action = action
        self.trigger = trigger
        self.attachments = attachments
        self.attendees = attendees
        self.description = description
        self.summary = summary
    }
}

extension UIEventAlarm {
    init(sdk: MultiplatformCalendar.EventAlarm) {
        action = UIAlarmAction(sdk: sdk.action)
        trigger = UIAlarmTrigger(sdk: sdk.trigger)
        attachments = sdk.attachments
        attendees = sdk.attendees
        description = sdk.description_
        summary = sdk.summary
    }
}

public enum UITriggerRelation: String, Sendable, Hashable, CaseIterable {
    case start
    case end
}

public enum UIAlarmTrigger: Sendable, Hashable {
    case relative(offset: TimeInterval, relatedTo: UITriggerRelation)
    case absolute(instant: Date)
}

public enum UIAlarmAction: Sendable, Hashable {
    case display
    case audio
    case email
    case unknown(raw: String)
}

public enum AlarmOffset: String, CaseIterable, Identifiable, Hashable {
    case none = "None"
    case fiveMinutesBefore = "5 minutes before"
    case oneHourBefore = "1 hour before"
    case oneHourAfter = "1 hour after"
    case fiveMinutesAfter = "5 minutes after"

    public var id: String {
        rawValue
    }

    public func triggerDate(for eventDate: Date) -> Date? {
        switch self {
        case .none: return nil
        case .fiveMinutesBefore: return Calendar.current.date(byAdding: .minute, value: -5, to: eventDate)
        case .fiveMinutesAfter: return Calendar.current.date(byAdding: .minute, value: +5, to: eventDate)
        case .oneHourBefore: return Calendar.current.date(byAdding: .hour, value: -1, to: eventDate)
        case .oneHourAfter: return Calendar.current.date(byAdding: .hour, value: +1, to: eventDate)
        }
    }

    public init(trigger: UIAlarmTrigger) {
        switch trigger {
        case .relative(let offset, let relatedTo):
            switch (offset, relatedTo) {
            case (-300, UITriggerRelation.start):
                self = .fiveMinutesBefore
            case (-3600, UITriggerRelation.start):
                self = .oneHourBefore
            case (-300, UITriggerRelation.end):
                self = .fiveMinutesAfter
            case(-3600, UITriggerRelation.end):
                self = .oneHourAfter
            default: self = .none
            }
        case .absolute:
            self = .none
        }
    }
}

public extension UIAlarmAction {
    init(sdk: any AlarmAction) {
        switch sdk {
        case is AlarmActionDisplay: self = .display
        case is AlarmActionAudio: self = .audio
        case is AlarmActionEmail: self = .email
        case let unknown as AlarmActionUnknown:
            self = .unknown(raw: unknown.raw)
        default:
            self = .unknown(raw: "")
        }
    }
}

extension UIAlarmTrigger {
    init(sdk: any AlarmTrigger) {
        switch sdk {
        case let relative as AlarmTriggerRelative:
            self = .relative(
                offset: TimeInterval(relative.offset),
                relatedTo: UITriggerRelation(sdk: relative.relatedTo)
            )
        case let absolute as AlarmTriggerAbsolute:
            self = .absolute(instant: absolute.instant.date)
        default:
            self = .absolute(instant: Date())
        }
    }
}

extension UITriggerRelation {
    init(sdk: TriggerRelation) {
        switch sdk {
        case .start: self = .start
        case .end: self = .end
        }
    }
}

/// Preview data for SwiftUI preview
public extension UIEventAlarm {
    static let preview = UIEventAlarm(
        action: .display,
        trigger: .relative(offset: -300, relatedTo: .start),
        attachments: [],
        attendees: ["tim@apple.com"],
        description: "Reminder: standup meeting",
        summary: "Daily Standup"
    )

    static let previews: [UIEventAlarm] = [
        UIEventAlarm(action: .display, trigger: .relative(offset: -300, relatedTo: .start),
                     attachments: [], attendees: ["tim@apple.com"],
                     description: "5 minutes before", summary: "Quick reminder"),
        UIEventAlarm(action: .email, trigger: .relative(offset: -3600, relatedTo: .end),
                     attachments: [], attendees: ["john@apple.com"],
                     description: "1 hour before", summary: "Prepare slides")
    ]
}
