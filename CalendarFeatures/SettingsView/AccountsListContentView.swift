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
import ESDSFoundation
import InfomaniakCoreCommonUI
import InfomaniakDI
import SwiftUI

public struct AccountsListContentView: View {
    @Environment(\.esdsTheme) private var theme
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var isShowingNewAccountView = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    let accountsArray = Array(calendarAccounts.values)

                    ForEach(accountsArray) { account in
                        NavigationLink {
                            AccountSettingsView(user: account.user)
                        } label: {
                            AccountCellView(
                                rawAvatarURL: account.user.avatar,
                                displayName: account.user.displayName,
                                email: account.user.email
                            )
                        }
                        .listRowSeparator(account.id == accountsArray.last?.id ? .visible : .hidden)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    }

                    Button("Add account") {
                        isShowingNewAccountView = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Ajouter un calendrier externe")
                                .font(.body.weight(.medium))
                                .foregroundStyle(theme.color.textPrimary)

                            Text("Abonnement via URL")
                                .font(.body)
                                .foregroundStyle(theme.color.textSecondary)
                        }
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
