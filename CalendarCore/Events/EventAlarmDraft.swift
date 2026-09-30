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
    public let trigger: UIAlarmTrigger

    public init(id: ID = .new(UUID()), action: UIAlarmAction, trigger: UIAlarmTrigger) {
        self.id = id
        self.action = action
        self.trigger = trigger
    }

    public init(action: UIAlarmAction = .display, offset: AlarmOffset) {
        self.init(
            action: action,
            trigger: offset.trigger
        )
    }

    public func newWith(offset newOffset: AlarmOffset) -> EventAlarmDraft {
        return EventAlarmDraft(
            id: id,
            action: action,
            trigger: newOffset.trigger
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
        case (.relative, .absolute):
            return true
        case (.absolute, .relative):
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
    }

    var sdkValue: EventAlarm {
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

    public var id: Self {
        return self
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

public enum AlarmOffset: CaseIterable, Identifiable, Hashable, Sendable {
    case atTimeOfEvent
    case fiveMinutesBefore
    case tenMinutesBefore
    case fifteenMinutesBefore
    case thirtyMinutesBefore
    case oneHourBefore
    case oneDayBefore

    public var id: Self {
        self
    }

    public var trigger: UIAlarmTrigger {
        switch self {
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
        }
    }

    public init?(trigger: UIAlarmTrigger) {
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
            default: return nil
            }

        default:
            return nil
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
