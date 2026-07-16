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
import DesignSystem
import Foundation
import SwiftUI

public struct PlanningView: View {
    @State private var displayedRange = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!

    @State private var planningViewModel: PlanningViewModel
    @State private var nextEventCardViewModel = NextEventCardViewModel()

    let calendarAccounts: [CalendarAccount.ID: CalendarAccount]

    public init(calendarAccounts: [CalendarAccount.ID: CalendarAccount]) {
        self.calendarAccounts = calendarAccounts
        _planningViewModel = State(wrappedValue: PlanningViewModel(calendarAccounts: calendarAccounts))
    }

    public var body: some View {
        PlanningCollectionView(planningViewModel: planningViewModel, nextEventCardViewModel: nextEventCardViewModel)
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                NextEventCardView(model: nextEventCardViewModel)
                    .padding(.horizontal, IKPadding.medium)
                    .padding(.vertical, IKPadding.mini)
            }
            .modifier(MiniCalendarHeaderViewModifier(displayedRange: $displayedRange))
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Today") {
                        withAnimation {
                            planningViewModel.scrollTarget = Date()
                        }
                    }
                }
            }
            .task {
                planningViewModel.scrollTarget = Date()
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
}
