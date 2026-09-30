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

/// Kotlin exports `kotlin.time.Duration` to Swift as its raw `Int64` encoding, not as seconds:
/// the lowest bit selects the unit (`0` for nanoseconds, `1` for milliseconds) and the remaining bits hold the value.
enum KotlinDuration {
    private static let maxNanoseconds: Int64 = 4_611_686_018_426_999_999
    private static let maxMilliseconds: Int64 = 4_611_686_018_427_387_903
    private static let nanosecondsPerSecond: TimeInterval = 1_000_000_000
    private static let millisecondsPerSecond: TimeInterval = 1000

    static func rawValue(fromTimeInterval interval: TimeInterval) -> Int64 {
        let nanoseconds = (interval * nanosecondsPerSecond).rounded()
        if abs(nanoseconds) <= TimeInterval(maxNanoseconds) {
            return Int64(nanoseconds) << 1
        }

        let milliseconds = (interval * millisecondsPerSecond).rounded()
        let clamped = min(max(milliseconds, -TimeInterval(maxMilliseconds)), TimeInterval(maxMilliseconds))
        return (Int64(clamped) << 1) | 1
    }

    static func timeInterval(fromRawValue rawValue: Int64) -> TimeInterval {
        let value = rawValue >> 1
        if rawValue & 1 == 0 {
            return TimeInterval(value) / nanosecondsPerSecond
        }
        return TimeInterval(value) / millisecondsPerSecond
    }
}
