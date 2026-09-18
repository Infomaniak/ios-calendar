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
import InfomaniakDI
import MultiplatformCalendar
import Observation
import SwiftUI

@Observable
final class DaysViewModel {
    var events = [Date: [CalendarCoreUI.UIEvent]]()

    func events(for date: Date, calendar: Foundation.Calendar) -> [CalendarCoreUI.UIEvent] {
        return events[date.startOfDay(calendar)] ?? []
    }
}

struct DayPager: View {
    @Binding var selectedDate: Date
    @Binding var miniCalendarHeight: CGFloat

    var body: some View {
        GeometryReader { proxy in
            CalendarPeriodPager(
                component: .day,
                periodOffsets: -36525 ..< 36526,
                date: $selectedDate
            ) { date in
                DayView(
                    miniCalendarHeight: $miniCalendarHeight,
                    date: date
                )
                // The horizontal scroll view consumes these insets; restore them for each timeline.
                // DayContentView already reserves the mini-calendar's height.
                .safeAreaPadding(EdgeInsets(
                    top: max(0, proxy.safeAreaInsets.top - miniCalendarHeight),
                    leading: proxy.safeAreaInsets.leading,
                    bottom: proxy.safeAreaInsets.bottom,
                    trailing: proxy.safeAreaInsets.trailing
                ))
            }
            .modifier(IgnoreTopSafeAreaModifier())
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}

struct DaysView: View {
    @Environment(\.calendar) private var calendar
    @Environment(MainViewState.self) private var mainViewState
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var viewModel = DaysViewModel()

    @Binding var miniCalendarHeight: CGFloat

    var body: some View {
        @Bindable var mainViewState = mainViewState

        DayPager(selectedDate: $mainViewState.selectedDate, miniCalendarHeight: $miniCalendarHeight)
            .environment(viewModel)
            .sensoryFeedback(trigger: mainViewState.selectedDate) { oldValue, newValue in
                guard !calendar.isDate(oldValue, inSameDayAs: newValue) else {
                    return nil
                }
                return .selection
            }
            .task(id: mainViewState.selectedDate) {
                await observeCalendars(mainViewState.selectedDate)
            }
    }

    private func observeCalendars(_ date: Date) async {
        let centerDate = date.startOfDay(calendar)
        let startDate = calendar.date(byAdding: .day, value: -3, to: centerDate) ?? centerDate
        let endDate = calendar.date(byAdding: .day, value: 3, to: centerDate) ?? centerDate

        @InjectService var calendarSDK: CalendarCoreGraph
        for await daySlices in calendarSDK.calendarManager.observeDaySlices(start: startDate.instant, end: endDate.instant) {
            guard !Task.isCancelled else {
                return
            }

            let uiEvents = daySlices.values.flatMap { eventDaySlices in
                eventDaySlices.compactMap {
                    let account = calendarAccounts[Int($0.event.accountIdValue)]
                    return CalendarCoreUI.UIEvent(eventDaySlice: $0, userEmail: account?.user.email ?? "")
                }
            }

            let groupedEvents = Dictionary(grouping: uiEvents) { $0.startDate.startOfDay(calendar) }
            viewModel.events = groupedEvents
        }
    }
}

private struct IgnoreTopSafeAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .ignoresSafeArea(.all, edges: .top)
        } else {
            content
        }
    }
}

#Preview {
    DaysView(miniCalendarHeight: .constant(0))
}
