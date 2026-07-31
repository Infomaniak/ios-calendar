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
import CalendarResources
import SwiftUI

extension CalendarViewMode {
    var icon: Image {
        switch self {
        case .planning:
            return CalendarResourcesAsset.Images.rowsTwo.swiftUIImage
        case .day:
            return CalendarResourcesAsset.Images.overlineRectangleUnderline.swiftUIImage
        case .threeDays:
            return CalendarResourcesAsset.Images.columnsThree.swiftUIImage
        case .week:
            return CalendarResourcesAsset.Images.columnsFour.swiftUIImage
        case .month:
            return CalendarResourcesAsset.Images.gridThreeTwo.swiftUIImage
        }
    }

    var localizedName: String {
        switch self {
        case .planning:
            return CalendarResourcesStrings.planningTitle
        case .day:
            return CalendarResourcesStrings.dayTitle
        case .threeDays:
            return CalendarResourcesStrings.threeDaysTitle
        case .week:
            return CalendarResourcesStrings.weekTitle
        case .month:
            return CalendarResourcesStrings.monthTitle
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
            case .threeDays:
                Text("Three Days View")
            case .month:
                MonthView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Picker(selection: $selectedMode) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Label {
                            Text(mode.localizedName)
                        } icon: {
                            mode.icon
                        }
                        .tag(mode)
                    }
                } label: {
                    Label {
                        Text(selectedMode.localizedName)
                    } icon: {
                        selectedMode.icon
                    }
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
