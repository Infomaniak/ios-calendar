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
    @State private var displayMode: MiniCalendarView.DisplayMode
    @State private var barItems = [SafeAreaBarItem]()
    @State private var miniCalendarHeight: CGFloat = 0
    @State private var barItemsHeight: CGFloat = 0

    @Binding var selectedDate: Date

    init(
        selectedDate: Binding<Date>,
        initialDisplayMode: MiniCalendarView.DisplayMode = .week
    ) {
        _displayMode = State(initialValue: initialDisplayMode)
        _selectedDate = selectedDate
    }

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                content
                    .safeAreaBar(edge: .top, spacing: 0) {
                        VStack(spacing: 0) {
                            MiniCalendarView(
                                displayMode: $displayMode,
                                selectedDate: $selectedDate
                            )
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.size.height
                            } action: { newHeight in
                                miniCalendarHeight = newHeight
                            }

                            // Bar items are drawn in an overlay: scrollable content inside the bar
                            // inflates the scroll edge effect and glitches when it bounces.
                            Color.clear
                                .frame(height: barItemsHeight)
                                .glassEffect(.identity, in: Rectangle())
                                .allowsHitTesting(false)
                        }
                    }
                    .overlay(alignment: .top) {
                        VStack(spacing: 0) {
                            barItemsView
                        }
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.height
                        } action: { newHeight in
                            barItemsHeight = newHeight
                        }
                        .padding(.top, miniCalendarHeight)
                    }
            } else {
                content
                    .safeAreaInset(edge: .top, spacing: 0) {
                        VStack(spacing: 0) {
                            MiniCalendarView(
                                displayMode: $displayMode,
                                selectedDate: $selectedDate
                            )

                            barItemsView
                        }
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
                    Button(action: switchDisplayMode) {
                        AnimatedTitleView(date: selectedDate)
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
                    AnimatedTitleView(date: selectedDate)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onPreferenceChange(SafeAreaBarItemsKey.self) { items in
            barItems = items
        }
    }

    private var barItemsView: some View {
        ForEach(barItems) { item in
            item.content
        }
    }

    private func switchDisplayMode() {
        withAnimation {
            displayMode = displayMode == .month ? .week : .month
        }
    }
}
