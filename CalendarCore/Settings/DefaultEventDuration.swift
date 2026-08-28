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
import SwiftUI

public enum DefaultEventDuration: CaseIterable, Sendable {
    case fifteenminutes
    case twentynminutes
    case thirtyminutes
    case fortyfiveminutes
    case onehour
    case onehourandfifteenminutes
    case onehourandthirtyminutes
    case onehourandfortyfiveminutes
    case twohours
//    case personalization(value: Int)

    public static var allCases: [DefaultEventDuration] {
        [.fifteenminutes, .twentynminutes, .thirtyminutes, .fortyfiveminutes,
         .onehour, .onehourandfifteenminutes, .onehourandthirtyminutes,
         .onehourandfortyfiveminutes, .twohours]
    }

    public var minutes: Int {
        switch self {
        case .fifteenminutes: return 15
        case .twentynminutes: return 20
        case .thirtyminutes: return 30
        case .fortyfiveminutes: return 45
        case .onehour: return 60
        case .onehourandfifteenminutes: return 75
        case .onehourandthirtyminutes: return 90
        case .onehourandfortyfiveminutes: return 105
        case .twohours: return 120
//        case .personalization(let value): return value
        }
    }

    public init(minutes: Int) {
        self = Self.allCases.first { $0.minutes == minutes } ?? .thirtyminutes
//        ?? .personalization(value: minutes)
    }

    public var title: String {
        switch self {
        case .fifteenminutes:
            return "15 min"
        case .twentynminutes:
            return "20 min"
        case .thirtyminutes:
            return "30 min"
        case .fortyfiveminutes:
            return "45 min"
        case .onehour:
            return "1 h"
        case .onehourandfifteenminutes:
            return "1 h 15 min"
        case .onehourandthirtyminutes:
            return "1 h 30 min"
        case .onehourandfortyfiveminutes:
            return "1 h 45 min"
        case .twohours:
            return "2 h"
//        case .personalization(let minutes):
//            let hours = minutes / 60
//            let remainingMinutes = minutes % 60
//
//            if hours > 0 {
//                if remainingMinutes > 0 {
//                    return "\(hours) h \(remainingMinutes) min"
//                } else {
//                    return "\(hours) h"
//                }
//            } else {
//                return "\(minutes) min"
//            }
        }
    }
}
