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
import InfomaniakDI
import SwiftUI

public struct AccountSettingsView: View {
    @Environment(\.esdsTheme) private var theme

    @InjectService private var accountManager: AccountManager

    @State private var maskedAccount = false
    @State private var isPresentedLogOutAlert = false
    @State private var isPresentedConfirmLogOutAlert = false

    private var calendarAccount: CalendarAccount

    public init(
        calendarAccount: CalendarAccount
    ) {
        self.calendarAccount = calendarAccount
    }

    public var body: some View {
        Form {
            Section {
                AccountCellView(
                    rawAvatarURL: calendarAccount.user.avatar,
                    displayName: calendarAccount.user.displayName,
                    email: calendarAccount.user.email
                )
            }

            Section {
                Toggle("Masquer le compte", isOn: $maskedAccount)
                    .toggleStyle(SwitchToggleStyle())
                Button("Supprimer le compte") {
                    print("Supprimer le compte")
                }
                .font(.body)
                .foregroundStyle(theme.color.textPrimary)

                Button("Se déconnecter") {
                    isPresentedLogOutAlert = true
                }
                .alert(
                    "Déconnecter le compte “\(calendarAccount.user.displayName)”",
                    isPresented: $isPresentedLogOutAlert,
                    actions: {
                        Button(role: .destructive) {
                            Task {
                                await accountManager.removeAccountFor(userId: calendarAccount.user.id)
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
                            // Logic close and open onboarding (if more 0 account) or juste back
                        } label: {
                            Text("Fermer")
                        }
                    }
                )
                .foregroundStyle(theme.color.textFeedbackErrorDefault)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle(calendarAccount.user.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
