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
import SwiftUI

extension CalendarViewMode {
    var iconName: String {
        switch self {
        case .planning:
            return "rectangle.split.1x2"
        case .day:
            return "distribute.vertical"
        case .week:
            return "distribute.vertical"
        case .month:
            return "distribute.vertical"
        }
    }
}

public struct CalendarView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts

    @SceneStorage("SelectedMode") private var selectedMode: CalendarViewMode = .day

    public init() {}

    public var body: some View {
        Group {
            switch selectedMode {
            case .planning:
                PlanningView(calendarAccounts: calendarAccounts)
            case .day:
                DaysView()
            case .week:
                WeekView()
            case .month:
                MonthView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Picker(selection: $selectedMode) {
                    Label("Planning", systemImage: "rectangle.split.1x2")
                        .tag(CalendarViewMode.planning)
                    Label("Day", systemImage: "distribute.vertical")
                        .tag(CalendarViewMode.day)
                } label: {
                    Label("Calendar layout", systemImage: selectedMode.iconName)
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .bottomBar)
            }

            ToolbarItem(placement: .bottomBar) {
                Button("New", systemImage: "plus") {}
                    .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    CalendarView()
}
