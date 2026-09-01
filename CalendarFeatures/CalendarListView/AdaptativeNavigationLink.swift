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
import SwiftUI

struct AdaptativeNavigationLink<Content: View, Destination: View>: View {
    @State private var isShowingSheet = false

    let isCompact: Bool
    @ViewBuilder let destination: Destination
    @ViewBuilder let label: Content

    var body: some View {
        if isCompact {
            NavigationLink { destination } label: { label }
        } else {
            Button {
                isShowingSheet = true
            } label: {
                label
            }
            .sheet(isPresented: $isShowingSheet) {
                NavigationStack {
                    destination
                        .closeToolbarItem {
                            isShowingSheet = false
                        }
                }
            }
        }
    }
}

#Preview {
    AdaptativeNavigationLink(isCompact: true) {
        Text("Destination")
    } label: {
        Text("Hello")
    }
}
