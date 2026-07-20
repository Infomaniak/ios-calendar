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

import MultiplatformCalendar
import Sentry

public extension MultiplatformCalendar.CrashReportLevel {
    var sentryLevel: SentryLevel {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .fatal:
            return .fatal
        }
    }
}

public final class CrashReportService: CrashReport, Sendable {
    public static let shared = CrashReportService()

    private init() {
        SentrySDK.start { options in
            options.dsn = "https://6d4287f6f48b248aea43e684985d83b7@sentry-mobile.infomaniak.com/28"
            options.environment = Bundle.main.isRunningInTestFlight ? "testflight" : "production"
            options.tracePropagationTargets = []
            options.enableUIViewControllerTracing = false
            options.enableUserInteractionTracing = false
            options.enableNetworkTracking = false
            options.enableNetworkBreadcrumbs = false
            options.enableSwizzling = false
            options.enableMetricKit = true
            options.sessionReplay.sessionSampleRate = 0
            options.sessionReplay.onErrorSampleRate = 0

            options.beforeSend = { event in
                // if the application is in debug mode discard the events
                #if DEBUG || TEST
                return nil
                #else
                if UserDefaults.shared.isSentryAuthorized {
                    return event
                } else {
                    return nil
                }
                #endif
            }
        }
    }

    public func addBreadcrumb(
        message: String,
        category: String,
        level: MultiplatformCalendar.CrashReportLevel,
        type: MultiplatformCalendar.BreadcrumbType,
        data: [String: String]?
    ) {
        let breadcrumb = Breadcrumb(level: level.sentryLevel, category: category)
        breadcrumb.message = message
        breadcrumb.data = data
        breadcrumb.type = type.value
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    public func capture(message: String, exception: KotlinThrowable, data: [String: String]?) {
        let event = Event()
        event.message = SentryMessage(formatted: message)
        event.error = KotlinThrowableWrapper(kotlinThrowable: exception)

        SentrySDK.capture(event: event) { scope in
            if let data {
                scope.setExtras(data)
            }
        }
    }

    public func capture(message: String, data: [String: String]?, level: MultiplatformCalendar.CrashReportLevel?) {
        SentrySDK.capture(message: message) { scope in
            if let data {
                scope.setExtras(data)
            }
            if let level {
                scope.setLevel(level.sentryLevel)
            }
        }
    }
}
