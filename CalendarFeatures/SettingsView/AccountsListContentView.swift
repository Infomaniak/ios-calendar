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
import CalendarOnboardingView
import DesignSystem
import InfomaniakCoreCommonUI
import InfomaniakDI
import SwiftUI

public struct AccountsListContentView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var isShowingNewAccountView = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Section {
                List {
                    ForEach(Array(calendarAccounts.values)) { account in
                        NavigationLink {
                            AccountSettingsView(user: account.user)
                        } label: {
                            AccountCellView(
                                rawAvatarURL: account.user.avatar,
                                displayName: account.user.displayName,
                                email: account.user.email
                            )
                        }
                        .listRowSeparator(.hidden)
                    }
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.horizontal, IKPadding.medium)
                        Button("Add account") {
                            isShowingNewAccountView = true
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, IKPadding.medium)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            }
            .fullScreenCover(isPresented: $isShowingNewAccountView, onDismiss: {
                @InjectService var orientationManager: OrientationManageable
                orientationManager.setOrientationLock(.all)
            }, content: {
                SingleOnboardingView()
            })
            .navigationTitle("Comptes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AccountsListContentView()
}
