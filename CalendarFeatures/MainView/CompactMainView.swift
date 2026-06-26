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
import CalendarResources
import SwiftUI

public struct CompactMainView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts
    @State private var isShowingCalendarListView = false
    public var body: some View {
        NavigationStack {
            Text("MainView")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isShowingCalendarListView = true
                        } label: {
                            CalendarResourcesAsset.Images.burger.swiftUIImage
                        }
                    }
                }
        }
        .sheet(isPresented: $isShowingCalendarListView) {
            NavigationStack {
                CalendarListView()
            }
        }
    }
}
