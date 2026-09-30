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

public struct EventAlarmDraft: Sendable, Hashable, Identifiable {
    public var id: String {
        return uid
    }

    public let uid: String
    public let action: UIAlarmAction
    public let trigger: UIAlarmTrigger?
    public let description: String?
    public let summary: String?
    public let attendees: [String]
    public let attachments: [String]
    public var offset: AlarmOffset
    public let repetition: Repetition?

    public struct Repetition: Sendable, Hashable {
        public let count: Int32
        public let interval: TimeInterval

        public init(count: Int32, interval: TimeInterval) {
            self.count = count
            self.interval = interval
        }
    }

    public init(
        action: UIAlarmAction,
        trigger: UIAlarmTrigger?,
        attachments: [String],
        attendees: [String],
        description: String?,
        summary: String?,
        uid: String? = nil,
        repetition: Repetition? = nil
    ) {
        self.action = action
        self.trigger = trigger
        self.attachments = attachments
        self.attendees = attendees
        self.description = description
        self.summary = summary
        self.uid = uid ?? UUID().uuidString
        self.repetition = repetition
        offset = AlarmOffset(trigger: trigger)
    }

    public init(offset: AlarmOffset, action: UIAlarmAction = .display) {
        self.init(
            action: action,
            trigger: offset.trigger,
            attachments: [],
            attendees: [],
            description: nil,
            summary: nil
        )
    }

    public func with(offset newOffset: AlarmOffset) -> EventAlarmDraft {
        return with(trigger: newOffset.trigger, action: action)
    }

    public func with(trigger: UIAlarmTrigger?, action: UIAlarmAction) -> EventAlarmDraft {
        return EventAlarmDraft(
            action: action,
            trigger: trigger,
            attachments: attachments,
            attendees: attendees,
            description: description,
            summary: summary,
            uid: uid,
            repetition: repetition
        )
    }

    func toSDK() -> EventAlarm? {
        guard let trigger else { return nil }
        let sdkRepetition: AlarmRepetition?
        if let repetition {
            sdkRepetition = AlarmRepetition(
                count: repetition.count,
                interval: KotlinDuration.rawValue(fromTimeInterval: repetition.interval)
            )
        } else {
            sdkRepetition = nil
        }
        return EventAlarm(
            action: action.sdkValue,
            trigger: trigger.sdkValue,
            description: description,
            summary: summary,
            attendees: attendees,
            attachments: attachments,
            uid: uid,
            repetition: sdkRepetition
        )
    }
}

public extension EventAlarmDraft {
    init(sdk: MultiplatformCalendar.EventAlarm) {
        uid = (sdk.uid as? String) ?? UUID().uuidString
        action = UIAlarmAction(sdk: sdk.action)
        trigger = UIAlarmTrigger(sdk: sdk.trigger)
        attachments = sdk.attachments
        attendees = sdk.attendees
        description = sdk.description_
        summary = sdk.summary
        offset = AlarmOffset(trigger: trigger)
        if let repetition = sdk.repetition {
            self.repetition = Repetition(
                count: repetition.count,
                interval: KotlinDuration.timeInterval(fromRawValue: repetition.interval)
            )
        } else {
            repetition = nil
        }
    }
}

public enum UIAlarmTrigger: Sendable, Hashable {
    case relative(offset: TimeInterval, relatedTo: TriggerRelation)
    case absolute(instant: Date)
}

public enum UIAlarmAction: Identifiable, Sendable, Hashable {
    case display
    case audio
    case email
    case unknown(String)

    public var id: String {
        switch self {
        case .display:
            return "display"
        case .audio:
            return "audio"
        case .email:
            return "email"
        case .unknown(let raw):
            return "unknown_\(raw)"
        }
    }

    public var isEditable: Bool {
        switch self {
        case .display, .email:
            return true
        default:
            return false
        }
    }
}

public enum AlarmOffset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case none
    case atTimeOfEvent
    case fiveMinutesBefore
    case tenMinutesBefore
    case fifteenMinutesBefore
    case thirtyMinutesBefore
    case oneHourBefore
    case oneDayBefore
    case fiveMinutesAfter
    case oneHourAfter

    public var id: String {
        rawValue
    }

    public static let presets: [AlarmOffset] = [
        .none,
        .atTimeOfEvent,
        .fiveMinutesBefore,
        .tenMinutesBefore,
        .fifteenMinutesBefore,
        .thirtyMinutesBefore,
        .oneHourBefore,
        .oneDayBefore
    ]

    public var trigger: UIAlarmTrigger? {
        switch self {
        case .none:
            return nil
        case .atTimeOfEvent:
            return .relative(offset: 0, relatedTo: .start)
        case .fiveMinutesBefore:
            return .relative(offset: -300, relatedTo: .start)
        case .tenMinutesBefore:
            return .relative(offset: -600, relatedTo: .start)
        case .fifteenMinutesBefore:
            return .relative(offset: -900, relatedTo: .start)
        case .thirtyMinutesBefore:
            return .relative(offset: -1800, relatedTo: .start)
        case .oneHourBefore:
            return .relative(offset: -3600, relatedTo: .start)
        case .oneDayBefore:
            return .relative(offset: -86400, relatedTo: .start)
        case .fiveMinutesAfter:
            return .relative(offset: 300, relatedTo: .end)
        case .oneHourAfter:
            return .relative(offset: 3600, relatedTo: .end)
        }
    }

    public func triggerDate(for startDate: Date, to endDate: Date) -> Date? {
        switch self {
        case .none: return nil
        case .atTimeOfEvent: return startDate
        case .fiveMinutesBefore: return Calendar.current.date(byAdding: .minute, value: -5, to: startDate)
        case .tenMinutesBefore: return Calendar.current.date(byAdding: .minute, value: -10, to: startDate)
        case .fifteenMinutesBefore: return Calendar.current.date(byAdding: .minute, value: -15, to: startDate)
        case .thirtyMinutesBefore: return Calendar.current.date(byAdding: .minute, value: -30, to: startDate)
        case .oneHourBefore: return Calendar.current.date(byAdding: .hour, value: -1, to: startDate)
        case .oneDayBefore: return Calendar.current.date(byAdding: .day, value: -1, to: startDate)
        case .fiveMinutesAfter: return Calendar.current.date(byAdding: .minute, value: +5, to: endDate)
        case .oneHourAfter: return Calendar.current.date(byAdding: .hour, value: +1, to: endDate)
        }
    }

    public init(trigger: UIAlarmTrigger?) {
        switch trigger {
        case .relative(let offset, let relatedTo):
            switch (offset, relatedTo) {
            case (0, .start):
                self = .atTimeOfEvent
            case (-300, .start):
                self = .fiveMinutesBefore
            case (-600, .start):
                self = .tenMinutesBefore
            case (-900, .start):
                self = .fifteenMinutesBefore
            case (-1800, .start):
                self = .thirtyMinutesBefore
            case (-3600, .start):
                self = .oneHourBefore
            case (-86400, .start):
                self = .oneDayBefore
            case (300, .end):
                self = .fiveMinutesAfter
            case (3600, .end):
                self = .oneHourAfter
            default: self = .none
            }

        default:
            self = .none
        }
    }
}

public extension UIAlarmAction {
    init(sdk: any AlarmAction) {
        switch onEnum(of: sdk) {
        case .display:
            self = .display
        case .audio:
            self = .audio
        case .email:
            self = .email
        case .unknown(let unknown):
            self = .unknown(unknown.raw)
        }
    }

    var sdkValue: any AlarmAction {
        switch self {
        case .display: return AlarmActionDisplay()
        case .audio: return AlarmActionAudio()
        case .email: return AlarmActionEmail()
        case .unknown(let raw): return AlarmActionUnknown(raw: raw)
        }
    }
}

extension UIAlarmTrigger {
    init(sdk: any AlarmTrigger) {
        switch onEnum(of: sdk) {
        case .absolute(let value):
            self = .absolute(instant: value.instant.toNSDate())
        case .relative(let value):
            self = .relative(
                offset: KotlinDuration.timeInterval(fromRawValue: value.offset),
                relatedTo: value.relatedTo
            )
        }
    }

    var sdkValue: any AlarmTrigger {
        switch self {
        case .relative(let offset, let relatedTo):
            return AlarmTriggerRelative(
                offset: KotlinDuration.rawValue(fromTimeInterval: offset),
                relatedTo: relatedTo
            )
        case .absolute(let instant):
            return AlarmTriggerAbsolute(instant: instant.instant)
        }
    }
}
