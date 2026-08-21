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
import CalendarResources
import DesignSystem
import ESDSFoundation
import InfomaniakCore
import InfomaniakDI
import InfomaniakLogin
import OSLog
import SwiftUI

public struct AccountSettingsView: View {
    @Environment(\.esdsTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @InjectService private var accountManager: AccountManager
    @InjectService private var tokenStore: TokenStore

    @State private var isAccountVisible = false
    @State private var isShowingLogOutAlert = false
    @State private var isShowingConfirmLogOutAlert = false
    @State private var delegate: AccountSettingsViewDelegate
    @State private var presentedAccountDeletionToken: ApiToken?

    private var user: UserProfile

    private var iconSize: CGFloat = 48

    public init(
        user: UserProfile
    ) {
        self.user = user
        _delegate = State(wrappedValue: AccountSettingsViewDelegate(userId: user.id))
    }

    public var body: some View {
        List {
            Section {
                Toggle(CalendarResourcesStrings.hideAccountToggle, isOn: $isAccountVisible)
                    .toggleStyle(SwitchToggleStyle())
                Button(CalendarResourcesStrings.buttonDeleteAccount) {
                    presentedAccountDeletionToken = tokenStore.tokenFor(userId: user.id)?.apiToken
                }
                .font(.body)
                .foregroundStyle(theme.color.contentPrimary)
                .disabled(true) // Temporarily disable it until the 403 issue is resolved

                Button(CalendarResourcesStrings.buttonLogOut, role: .destructive) {
                    isShowingLogOutAlert = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } header: {
                HStack(spacing: IKPadding.medium) {
                    AvatarView(rawAvatarURL: user.avatar, displayName: user.displayName,
                               email: user.email, size: iconSize)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(user.displayName)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(theme.color.contentPrimary)
                        Text(user.email)
                            .font(.title3)
                            .foregroundStyle(theme.color.contentSecondary)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .alert(
                CalendarResourcesStrings.signOutAccountAlertTitle(user.displayName),
                isPresented: $isShowingLogOutAlert,
                actions: {
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await accountManager.removeAccountFor(userId: user.id)
                            } catch {
                                Logger.general.error("Logout failed: \(error)")
                            }

                            isShowingConfirmLogOutAlert = true
                        }
                    } label: {
                        Text(CalendarResourcesStrings.signOutAccountAlertDescription)
                    }
                },
                message: {
                    Text(
                        CalendarResourcesStrings.signOutAccountAlertConfirm
                    )
                }
            )
            .alert(
                CalendarResourcesStrings.signOutAccountSuccessfulAlertTitle,
                isPresented: $isShowingConfirmLogOutAlert
            ) {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text(CalendarResourcesStrings.closeLabel)
                }
            }
            .sheet(item: $presentedAccountDeletionToken) { userToken in
                DeleteAccountView(token: userToken, delegate: delegate)
            }
            .navigationTitle(user.displayName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DeleteAccountView: UIViewControllerRepresentable {
    let token: ApiToken
    let delegate: DeleteAccountDelegate

    func makeUIViewController(context: Context) -> UINavigationController {
        return DeleteAccountViewController.instantiateInViewController(
            delegate: delegate,
            accessToken: token.accessToken,
            navBarColor: nil,
            navBarButtonColor: nil
        )
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Not needed
    }
}

extension ApiToken: @retroactive Identifiable {
    public var id: String {
        return "\(userId)\(accessToken)"
    }
}

@MainActor
final class AccountSettingsViewDelegate: DeleteAccountDelegate {
    @LazyInjectService private var accountManager: AccountManager

    let userId: Int

    init(userId: Int) {
        self.userId = userId
    }

    nonisolated func didCompleteDeleteAccount() {
        Task {
            do {
                try await accountManager.removeAccountFor(userId: userId)
            } catch {
                Logger.general.error("Logout failed: \(error)")
            }
        }
    }

    nonisolated func didFailDeleteAccount(error: InfomaniakLoginError) {
        Logger.general.error("Error during deletion: \(error)")
    }
}
