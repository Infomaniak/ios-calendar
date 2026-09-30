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
@preconcurrency import MultiplatformCalendar

public struct UIEventAlarm: Sendable, Hashable {
    public let action: UIAlarmAction
    public let trigger: UIAlarmTrigger?
    public let description: String?
    public let summary: String?
    public let attendees: [String]
    public let attachments: [String]
    public var offset: AlarmOffset

    public init(
        action: UIAlarmAction,
        trigger: UIAlarmTrigger?,
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

    public func with(offset newOffset: AlarmOffset) -> UIEventAlarm {
        return UIEventAlarm(
            action: action,
            trigger: newOffset.trigger,
            attachments: attachments,
            attendees: attendees,
            description: description,
            summary: summary
        )
    }

    public var label: String {
        guard let trigger else { return AlarmOffset.none.label }
        switch trigger {
        case .relative(let offset, _):
            let preset = AlarmOffset(trigger: trigger)
            guard preset == .none else { return preset.label }
            let duration = Duration.seconds(abs(offset))
                .formatted(.units(allowed: [.days, .hours, .minutes], width: .wide, maximumUnitCount: 2))
            return offset < 0
                ? CalendarResourcesStrings.alarmOffsetCustomBefore(duration)
                : CalendarResourcesStrings.alarmOffsetCustomAfter(duration)
        case .absolute(let date):
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }

    func toSDK() -> EventAlarm? {
        guard let trigger else { return nil }
        return EventAlarm(
            action: action.sdkValue,
            trigger: trigger.sdkValue,
            description: description,
            summary: summary,
            attendees: attendees,
            attachments: attachments,
            uid: nil,
            repetition: nil
        )
    }
}

public extension UIEventAlarm {
    init(sdk: MultiplatformCalendar.EventAlarm) {
        action = UIAlarmAction(sdk: sdk.action)
        trigger = UIAlarmTrigger(sdk: sdk.trigger)
        attachments = sdk.attachments
        attendees = sdk.attendees
        description = sdk.description_
        summary = sdk.summary
        offset = AlarmOffset(trigger: trigger)
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

    public var label: String {
        switch self {
        case .display:
            return CalendarResourcesStrings.notificationTypePush
        case .audio:
            return "Notification audio"
        case .email:
            return CalendarResourcesStrings.notificationTypeEmail
        case .unknown(let raw):
            return raw
        }
    }

    public var icon: CalendarResourcesImages {
        switch self {
        case .display:
            return CalendarResourcesAsset.Images.bubbleTopRightCircle
        case .audio:
            return CalendarResourcesAsset.Images.bell
        default:
            return CalendarResourcesAsset.Images.bell
        }
    }
}

public enum AlarmOffset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case none = "None"
    case atTimeOfEvent = "At the time of the event"
    case fiveMinutesBefore = "5 minutes before"
    case tenMinutesBefore = "10 minutes before"
    case fifteenMinutesBefore = "15 minutes before"
    case thirtyMinutesBefore = "30 minutes before"
    case oneHourBefore = "1 hour before"
    case oneDayBefore = "1 day before"
    case fiveMinutesAfter = "5 minutes after"
    case oneHourAfter = "1 hour after"

    public var id: String {
        rawValue
    }

    /// Presets offered when editing an alarm, in display order. Selecting `.none` removes the alarm.
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

    public var label: String {
        switch self {
        case .none:
            return CalendarResourcesStrings.alarmOffsetNone
        case .atTimeOfEvent:
            return CalendarResourcesStrings.alarmOffsetAtTimeOfEvent
        case .fiveMinutesBefore:
            return CalendarResourcesStrings.alarmOffsetFiveMinutesBefore
        case .tenMinutesBefore:
            return CalendarResourcesStrings.alarmOffsetTenMinutesBefore
        case .fifteenMinutesBefore:
            return CalendarResourcesStrings.alarmOffsetFifteenMinutesBefore
        case .thirtyMinutesBefore:
            return CalendarResourcesStrings.alarmOffsetThirtyMinutesBefore
        case .oneHourBefore:
            return CalendarResourcesStrings.alarmOffsetOneHourBefore
        case .oneDayBefore:
            return CalendarResourcesStrings.alarmOffsetOneDayBefore
        case .fiveMinutesAfter:
            return CalendarResourcesStrings.alarmOffsetFiveMinutesAfter
        case .oneHourAfter:
            return CalendarResourcesStrings.alarmOffsetOneHourAfter
        }
    }

    /// The trigger this preset maps to, or `nil` for `.none`.
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
            case (0, UITriggerRelation.start):
                self = .atTimeOfEvent
            case (-300, UITriggerRelation.start):
                self = .fiveMinutesBefore
            case (-600, UITriggerRelation.start):
                self = .tenMinutesBefore
            case (-900, UITriggerRelation.start):
                self = .fifteenMinutesBefore
            case (-1800, UITriggerRelation.start):
                self = .thirtyMinutesBefore
            case (-3600, UITriggerRelation.start):
                self = .oneHourBefore
            case (-86400, UITriggerRelation.start):
                self = .oneDayBefore
            case (300, UITriggerRelation.end):
                self = .fiveMinutesAfter
            case (3600, UITriggerRelation.end):
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
        switch sdk {
        case is AlarmActionDisplay: self = .display
        case is AlarmActionAudio: self = .audio
        case is AlarmActionEmail: self = .email
        case let unknown as AlarmActionUnknown:
            self = .unknown(unknown.raw)
        default:
            self = .unknown("")
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
    init?(sdk: any AlarmTrigger) {
        switch sdk {
        case let relative as AlarmTriggerRelative:
            self = .relative(
                offset: TimeInterval(relative.offset),
                relatedTo: UITriggerRelation(sdk: relative.relatedTo)
            )
        case let absolute as AlarmTriggerAbsolute:
            self = .absolute(instant: absolute.instant.toNSDate())
        default:
            return nil
        }
    }

    var sdkValue: any AlarmTrigger {
        switch self {
        case .relative(let offset, let relatedTo):
            return AlarmTriggerRelative(offset: Int64(offset), relatedTo: relatedTo.sdkValue)
        case .absolute(let instant):
            return AlarmTriggerAbsolute(instant: instant.instant)
        }
    }
}

extension UITriggerRelation {
    init(sdk: TriggerRelation) {
        // À adapter selon les cas réels du SDK
        switch sdk {
        case .start: self = .start
        case .end: self = .end
        }
    }

    var sdkValue: TriggerRelation {
        switch self {
        case .start: return TriggerRelation.start
        case .end: return TriggerRelation.end
        }
    }
}

/// Preview data for SwiftUI previews
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
                     description: "1 hour after", summary: "Prepare slides")
    ]
}
