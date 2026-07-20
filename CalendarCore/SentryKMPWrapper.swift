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

final class SentryKMPWrapper: CrashReport {
    func addBreadcrumb(
        message: String,
        category: String,
        level: MultiplatformCalendar.CrashReportLevel,
        type: MultiplatformCalendar.BreadcrumbType,
        data: [String: String]?
    ) {}

    func capture(message: String, exception: KotlinThrowable, data: [String: String]?) {}

    func capture(message: String, data: [String: String]?, level: MultiplatformCalendar.CrashReportLevel?) {}
}
