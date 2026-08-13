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
import DesignSystem
import ESDSFoundation
import InfomaniakCore
import InfomaniakDI
import InfomaniakLogin
import SwiftUI

public struct AccountSettingsView: View {
    @Environment(\.esdsTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @InjectService private var accountManager: AccountManager
    @InjectService private var tokenStore: TokenStore

    @State private var maskedAccount = false
    @State private var isPresentedLogOutAlert = false
    @State private var isPresentedConfirmLogOutAlert = false
    @State private var delegate: AccountSettingsViewDelegate
    @State private var presentedAccountDeletionToken: ApiToken?

    private var user: UserProfile

    public init(
        user: UserProfile
    ) {
        self.user = user
        _delegate = State(wrappedValue: AccountSettingsViewDelegate(userId: user.id))
    }

    public var body: some View {
        List {
            HStack(spacing: IKPadding.medium) {
                AvatarView(rawAvatarURL: user.avatar, displayName: user.displayName,
                           email: user.email, size: 52)

                VStack(alignment: .leading, spacing: 0) {
                    Text(user.displayName)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(theme.color.textPrimary)
                    Text(user.email)
                        .font(.title3)
                        .foregroundStyle(theme.color.textSecondary)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowBackground(Color.clear)

            Section {
                Toggle("Masquer le compte", isOn: $maskedAccount)
                    .toggleStyle(SwitchToggleStyle())
                Button("Supprimer le compte") {
                    presentedAccountDeletionToken = tokenStore.tokenFor(userId: user.id)?.apiToken
                }
                .font(.body)
                .foregroundStyle(theme.color.textPrimary)

                Button("Se déconnecter", role: .destructive) {
                    isPresentedLogOutAlert = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listSectionSpacing(IKPadding.mini)
        .alert(
            "Déconnecter le compte “\(user.displayName)”",
            isPresented: $isPresentedLogOutAlert,
            actions: {
                Button(role: .destructive) {
                    Task {
                        await accountManager.removeAccountFor(userId: user.id)
                        isPresentedConfirmLogOutAlert = true
                    }
                } label: {
                    Text("Déconnecter le compte")
                }
            },
            message: {
                Text(
                    "Ce compte et les calendriers associés seront déconnectés de l’app « Calendar ». Ils restent disponibles sur votre compte Infomaniak en ligne."
                )
            }
        )
        .alert(
            "Le compte a bien été déconnecté",
            isPresented: $isPresentedConfirmLogOutAlert,
            actions: {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("Fermer")
                }
            }
        )
        .sheet(item: $presentedAccountDeletionToken) { userToken in
            DeleteAccountView(token: userToken, delegate: delegate)
        }
        .navigationTitle(user.displayName)
        .navigationBarTitleDisplayMode(.inline)
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
            await accountManager.removeAccountFor(userId: userId)
            print("compte supprimé")
        }
    }

    nonisolated func didFailDeleteAccount(error: InfomaniakLoginError) {
        print("Erreur lors de la suppression : \(error)")
    }
}
