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

import CalendarCoreUI
import DesignSystem
import Foundation
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI

public struct PlanningView: View {
    @StateObject private var nextEventCardViewModel = NextEventCardViewModel()
    @State private var planningDays: [PlanningDay] = []

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            PlanningCollectionView(planningDays: planningDays, nextEventCardViewModel: nextEventCardViewModel)
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    NextEventCardView(model: nextEventCardViewModel)
                        .padding(.horizontal, IKPadding.medium)
                        .padding(.vertical, IKPadding.mini)
                }
        }
        .task {
            await observeEvents()
        }
    }

    private func observeEvents() async {
        @InjectService var calendarSDK: CalendarCoreGraph

        let oneWeek = Int64(Date(timeIntervalSinceNow: 60 * 60 * 24 * 7).timeIntervalSince1970) * 1000

        for await events in calendarSDK.calendarManager.observeEvents(
            start: .companion.fromEpochMilliseconds(epochMilliseconds: -oneWeek),
            end: .companion.fromEpochMilliseconds(epochMilliseconds: oneWeek),
        ) {
            let uiEvents = events.compactMap { UIEvent(event: $0, userEmail: "") }
            let days = PlanningDay.makeContiguousDays(from: uiEvents)

            withAnimation {
                planningDays = days
            }
        }
    }
}

#Preview {
    PlanningView()
}
