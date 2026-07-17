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
import DesignSystem
import Foundation
import SwiftUI

public struct PlanningView: View {
    @Environment(MainViewState.self) private var mainViewState: MainViewState

    @State private var planningViewModel: PlanningViewModel
    @State private var nextEventCardViewModel = NextEventCardViewModel()

    let calendarAccounts: [CalendarAccount.ID: CalendarAccount]

    public init(calendarAccounts: [CalendarAccount.ID: CalendarAccount]) {
        self.calendarAccounts = calendarAccounts
        _planningViewModel = State(wrappedValue: PlanningViewModel(calendarAccounts: calendarAccounts))
    }

    public var body: some View {
        @Bindable var mainViewState = mainViewState
        PlanningCollectionView(
            planningViewModel: planningViewModel,
            nextEventCardViewModel: nextEventCardViewModel,
            mainViewState: mainViewState
        )
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            NextEventCardView(model: nextEventCardViewModel)
                .padding(.horizontal, IKPadding.medium)
                .padding(.vertical, IKPadding.mini)
        }
        .modifier(MiniCalendarHeaderViewModifier(selectedDate: $mainViewState.selectedDate))
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Today") {
                    withAnimation {
                        mainViewState.selectedDate = Calendar.current.startOfDay(for: Date())
                    }
                }
            }
        }
        .onChange(of: mainViewState.selectedDate, initial: true) { _, newValue in
            guard !planningViewModel.suppressScrollTargetSync else {
                planningViewModel.suppressScrollTargetSync = false
                return
            }
            planningViewModel.scrollTarget = newValue
        }
        .id(calendarAccounts)
    }
}

#Preview {
    NavigationStack {
        PlanningView(calendarAccounts: [:])
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Menu", systemImage: "sidebar.left") {}
                }
            }
    }
    .environment(MainViewState())
}
