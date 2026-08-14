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
@preconcurrency import InfomaniakCore
import InfomaniakCoreSwiftUI
import InfomaniakCreateAccount
import InterAppLogin
import SwiftUI

struct OnboardingBottomButtonsView: View {
    @State private var isPresentingCreateAccount = false

    @ObservedObject var loginHandler: LoginHandler

    @Binding var selection: Int

    let slideCount: Int

    var dismissHandler: (() -> Void)?

    private var isLastSlide: Bool {
        selection == slideCount - 1
    }

    private var shouldDisplayInterAppLogin: Bool {
        #if DEBUG
        if ApiEnvironment.current == .prod {
            return false
        }
        #endif
        return true
    }

    var body: some View {
        ZStack {
            if isLastSlide {
                VStack(spacing: IKPadding.mini) {
                    ContinueWithAccountView(
                        isLoading: loginHandler.isLoading,
                        excludingUserIds: [],
                        allowsMultipleSelection: false,
                        shouldDisplayInterAppLogin: shouldDisplayInterAppLogin
                    ) {
                        loginPressed()
                    } onLoginWithAccountsPressed: { accounts in
                        loginWithAccountsPressed(accounts: accounts)
                    } onCreateAccountPressed: {
                        isPresentingCreateAccount = true
                    }
                }
                .ikButtonFullWidth(true)
                .controlSize(.large)
            } else {
                Button {
                    withAnimation {
                        selection = min(slideCount - 1, selection + 1)
                    }
                } label: {
                    Text("Next")
                }
                .buttonStyle(.ikSquare)
            }
        }
        .padding(.horizontal, value: .medium)
        .sheet(isPresented: $isPresentingCreateAccount) {
            CreateAccountView(loginHandler: loginHandler)
        }
    }

    private func loginPressed() {
        Task {
            await loginHandler.login(dimissHandler: dismissHandler)
        }
    }

    private func loginWithAccountsPressed(accounts: [ConnectedAccount]) {
        Task {
            await loginHandler.loginWith(accounts: accounts, dimissHandler: dismissHandler)
        }
    }
}

#Preview {
    OnboardingBottomButtonsView(loginHandler: LoginHandler(), selection: .constant(0), slideCount: 4)
}
