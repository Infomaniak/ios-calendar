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

public enum DefaultEventDuration: Sendable, Equatable, Hashable, RawRepresentable {
    private static let minimumTimeInterval: TimeInterval = 60

    case fifteenMinutes
    case twentyMinutes
    case thirtyMinutes
    case fortyFiveMinutes
    case oneHour
    case oneHourAndFifteenMinutes
    case oneHourAndThirtyMinutes
    case oneHourAndFortyFiveMinutes
    case twoHours

    public static let defaultCases: [DefaultEventDuration] = [
        .fifteenMinutes,
        .twentyMinutes,
        .thirtyMinutes,
        .fortyFiveMinutes,
        .oneHour,
        .oneHourAndFifteenMinutes,
        .oneHourAndThirtyMinutes,
        .oneHourAndFortyFiveMinutes,
        .twoHours
    ]

    public var timeInterval: TimeInterval {
        switch self {
        case .fifteenMinutes:
            return 15 * 60
        case .twentyMinutes:
            return 20 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .fortyFiveMinutes:
            return 45 * 60
        case .oneHour:
            return 60 * 60
        case .oneHourAndFifteenMinutes:
            return 75 * 60
        case .oneHourAndThirtyMinutes:
            return 90 * 60
        case .oneHourAndFortyFiveMinutes:
            return 105 * 60
        case .twoHours:
            return 120 * 60
        }
    }

    public init(timeInterval: TimeInterval) {
        let timeInterval = max(timeInterval, Self.minimumTimeInterval)
        self = Self.defaultCases.first { $0.timeInterval == timeInterval } ?? .thirtyMinutes
    }

    public init(rawValue: Int) {
        self.init(timeInterval: TimeInterval(rawValue))
    }

    public var rawValue: Int {
        Int(timeInterval)
    }
}
