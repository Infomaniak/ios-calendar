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

import CalendarCalendarListView
import CalendarCalendarView
import CalendarCoreUI
import SwiftUI

public struct RegularMainView: View {
    @Environment(MainViewState.self) private var mainViewState

    public var body: some View {
        NavigationSplitView {
            CalendarListView(isCompact: false)
                .topBar {
                    @Bindable var mainViewState = mainViewState
                    MiniCalendarView(selectedDate: $mainViewState.selectedDate, displayMode: .month)
                }
        } detail: {
            NavigationStack {
                CalendarView()
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func topBar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .top, spacing: 0, content: content)
        } else {
            safeAreaInset(edge: .top, spacing: 0) {
                content()
                    .background(Material.bar)
            }
        }
    }
}
