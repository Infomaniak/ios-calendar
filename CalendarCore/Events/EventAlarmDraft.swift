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

public struct EventAlarmDraft: Sendable, Hashable, Identifiable, Comparable {
    public enum ID: Sendable, Hashable {
        public static func == (lhs: EventAlarmDraft.ID, rhs: EventAlarmDraft.ID) -> Bool {
            switch (lhs, rhs) {
            case (.new(let left), .new(let right)):
                return left == right
            case (.existing(let left), .existing(let right)):
                return left.value == right.value
            default:
                return false
            }
        }

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .new(let uuid):
                hasher.combine(uuid)
            case .existing(let alarmId):
                hasher.combine(alarmId.value)
            }
        }

        case new(UUID)
        case existing(any AlarmId)
    }

    public let id: ID
    public let action: UIAlarmAction
    public let trigger: UIAlarmTrigger?
    public var offset: AlarmOffset

    public init(
        id: ID = .new(UUID()),
        action: UIAlarmAction,
        trigger: UIAlarmTrigger?
    ) {
        self.action = action
        self.trigger = trigger
        self.id = id
        offset = AlarmOffset(trigger: trigger)
    }

    public init(offset: AlarmOffset, action: UIAlarmAction = .display) {
        self.init(
            action: action,
            trigger: offset.trigger
        )
    }

    public func with(offset newOffset: AlarmOffset) -> EventAlarmDraft {
        return with(trigger: newOffset.trigger, action: action)
    }

    public func with(trigger: UIAlarmTrigger?, action: UIAlarmAction) -> EventAlarmDraft {
        return EventAlarmDraft(
            id: id,
            action: action,
            trigger: trigger
        )
    }

    public static func < (lhs: EventAlarmDraft, rhs: EventAlarmDraft) -> Bool {
        if lhs.action != rhs.action {
            return lhs.action < rhs.action
        }
        switch (lhs.trigger, rhs.trigger) {
        case (.relative(let left, _), .relative(let right, _)):
            return left < right
        case (.absolute(let left), .absolute(let right)):
            return left < right
        case (.relative, .absolute), (.some, nil):
            return true
        default:
            return false
        }
    }
}

public extension EventAlarmDraft {
    init(eventAlarm: MultiplatformCalendar.EventAlarm) {
        if let uid = eventAlarm.id {
            id = .existing(uid)
        } else {
            id = .new(UUID())
        }
        action = UIAlarmAction(alarmAction: eventAlarm.action)
        trigger = UIAlarmTrigger(alarmTrigger: eventAlarm.trigger)
        offset = AlarmOffset(trigger: trigger)
    }

    var sdkValue: EventAlarm? {
        guard let trigger else { return nil }
        switch id {
        case .new:
            return EventAlarm(action: action.sdkValue, trigger: trigger.sdkValue)
        case .existing(let uid):
            return EventAlarm(action: action.sdkValue, trigger: trigger.sdkValue, id: uid)
        }
    }
}

public extension EventAlarmDraft {
    static let preview = EventAlarmDraft(
        action: .display,
        trigger: .relative(offset: -300, relatedTo: .start)
    )

    static let previews: [EventAlarmDraft] = [
        EventAlarmDraft(action: .display, trigger: .relative(offset: -300, relatedTo: .start)),
        EventAlarmDraft(action: .email, trigger: .relative(offset: -3600, relatedTo: .end))
    ]
}

public enum UIAlarmTrigger: Sendable, Hashable {
    case relative(offset: TimeInterval, relatedTo: TriggerRelation)
    case absolute(instant: Date)
}

public enum UIAlarmAction: Identifiable, Sendable, Hashable, Comparable {
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

    public static func < (lhs: UIAlarmAction, rhs: UIAlarmAction) -> Bool {
        if lhs.sortOrder != rhs.sortOrder {
            return lhs.sortOrder < rhs.sortOrder
        }
        if case .unknown(let left) = lhs, case .unknown(let right) = rhs {
            return left < right
        }
        return false
    }

    private var sortOrder: Int {
        switch self {
        case .email: 0
        case .display: 1
        case .audio: 2
        case .unknown: 3
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
    init(alarmAction: any AlarmAction) {
        switch onEnum(of: alarmAction) {
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

public extension UIAlarmTrigger {
    init(alarmTrigger: any AlarmTrigger) {
        switch onEnum(of: alarmTrigger) {
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
