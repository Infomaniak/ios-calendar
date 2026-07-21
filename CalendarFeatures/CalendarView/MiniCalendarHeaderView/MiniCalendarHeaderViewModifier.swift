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

import DesignSystem
import SwiftUI

struct MiniCalendarHeaderViewModifier: ViewModifier {
    @Binding var selectedDate: Date

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                content
                    .safeAreaBar(edge: .top) {
                        MiniCalendarView()
                            .frame(height: 54)
                            .padding(.bottom, IKPadding.mini)
                    }
            } else {
                content
                    .safeAreaInset(edge: .top) {
                        MiniCalendarView()
                            .frame(height: 54)
                            .padding(.bottom, IKPadding.mini)
                            .background(Material.bar)
                            .onAppear {
                                let navBarAppearance = UINavigationBarAppearance()
                                navBarAppearance.shadowImage = nil
                                navBarAppearance.shadowColor = nil
                                UINavigationBar.appearance().standardAppearance = navBarAppearance
                            }
                    }
            }
        }
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .principal) {
                    Button {} label: {
                        HStack {
                            Text(selectedDate, format: .dateTime.year().month(.wide))
                            Image(systemName: "chevron.down")
                        }
                    }
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .topBarTrailing) {
                    Spacer()
                        .frame(width: 96)
                }
                .sharedBackgroundVisibility(.hidden)

            } else {
                ToolbarItem(placement: .topBarLeading) {
                    Text(selectedDate, format: .dateTime.year().month(.wide))
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
