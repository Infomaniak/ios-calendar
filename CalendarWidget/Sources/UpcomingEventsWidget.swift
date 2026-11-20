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

import CalendarCore
import CalendarCoreUI
import CalendarResources
import ESDSCalendar
import Foundation
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI
import WidgetKit

struct UpcomingEventsWidget: Widget {
    static let kind = "UpcomingEventsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: UpcomingEventsWidgetProvider()) { entry in
            UpcomingEventsWidgetView(entry: entry)
                .esdsTheme(.calendar)
        }
        .configurationDisplayName(CalendarResourcesStrings.upcomingEventsWidgetTitle)
        .description(CalendarResourcesStrings.upcomingEventsWidgetDescription)
        .supportedFamilies([.systemSmall])
    }
}

struct UpcomingEventsWidgetEntry: TimelineEntry {
    let date: Date
    let calendar: Foundation.Calendar
    let events: [UIEventSummary]
}

enum UpcomingEventsWidgetError: Error {
    case noAccount
}

struct UpcomingEventsWidgetProvider: TimelineProvider {
    private static let timelineDayCount = 2
    private static let refreshInterval: TimeInterval = 15 * 60

    private static var userCalendar: Foundation.Calendar {
        var calendar = Foundation.Calendar.autoupdatingCurrent
        calendar.firstWeekday = UserDefaults.shared.firstWeekday
        if let timeZoneIdentifier = UserDefaults.shared.timeZoneIdentifier,
           let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        return calendar
    }

    func placeholder(in context: Context) -> UpcomingEventsWidgetEntry {
        UpcomingEventsWidgetEntry(
            date: .now,
            calendar: .current,
            events: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (UpcomingEventsWidgetEntry) -> Void) {
        Task {
            let now = Date.now
            let calendar = Self.userCalendar
            do {
                try await Self.loadAccounts()
            } catch {
                completion(UpcomingEventsWidgetEntry(date: now, calendar: calendar, events: []))
                return
            }

            let events = await Self.todayEvents(now: now, calendar: calendar)
            completion(UpcomingEventsWidgetEntry(date: now, calendar: calendar, events: events.upcoming(at: now)))
        }
    }

    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<UpcomingEventsWidgetEntry>) -> Void
    ) {
        Task {
            let now = Date.now
            let calendar = Self.userCalendar
            let refreshPolicy = TimelineReloadPolicy.after(now.addingTimeInterval(Self.refreshInterval))

            do {
                try await Self.loadAccounts()
            } catch {
                let entry = UpcomingEventsWidgetEntry(date: now, calendar: calendar, events: [])
                completion(Timeline(entries: [entry], policy: refreshPolicy))
                return
            }

            let startOfToday = now.startOfDay(calendar)

            @InjectService var calendarSDK: CalendarCoreGraph
            if let endOfTimeline = calendar.date(byAdding: .day, value: Self.timelineDayCount, to: startOfToday) {
                await calendarSDK.calendarManager.downloadEvents(in: DateInterval(start: startOfToday, end: endOfTimeline))
            }

            var entries = [UpcomingEventsWidgetEntry]()
            for dayOffset in 0 ..< Self.timelineDayCount {
                guard let startOfDay = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday),
                      let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

                let firstEntryDate = max(now, startOfDay)
                let events = await calendarSDK.calendarManager.planningEvents(on: startOfDay, calendar: calendar)
                let refreshDates = Set(events.map(\.endDate).filter { $0 > firstEntryDate && $0 < endOfDay })
                entries += ([firstEntryDate] + refreshDates.sorted()).map { date in
                    UpcomingEventsWidgetEntry(date: date, calendar: calendar, events: events.upcoming(at: date))
                }
            }

            completion(Timeline(entries: entries, policy: refreshPolicy))
        }
    }

    private static func loadAccounts() async throws(UpcomingEventsWidgetError) {
        @InjectService var accountManager: CalendarCore.AccountManager
        await accountManager.loadAccounts()
        guard await !accountManager.calendarAccounts.isEmpty else {
            throw .noAccount
        }
    }

    private static func todayEvents(now: Date, calendar: Foundation.Calendar) async -> [UIEventSummary] {
        @InjectService var calendarSDK: CalendarCoreGraph
        return await calendarSDK.calendarManager.planningEvents(on: now, calendar: calendar)
    }
}
