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
import InfomaniakCore
import InfomaniakDI
import SwiftUI

public struct PreloadingView: View {
    @EnvironmentObject private var rootViewState: RootViewState

    private let backgroundImage = Image("splashscreen-background", bundle: .main)
    private let logoImage = Image("splashscreen-calendar", bundle: .main)
    private let infomaniakLogoImage = Image("splashscreen-infomaniak", bundle: .main)

    public init() {}

    public var body: some View {
        ZStack(alignment: .center) {
            backgroundImage
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            VStack(spacing: IKPadding.large) {
                logoImage
                    .frame(maxHeight: .infinity)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            infomaniakLogoImage
                .padding(.bottom, value: .medium)
        }
        .task { await preloadAndTransitionToRootView() }
    }

    func preloadAndTransitionToRootView() async {
        @InjectService var tokenStore: TokenStore
        @InjectService var appLaunchCounter: AppLaunchCounter

        guard !appLaunchCounter.isFirstLaunch else {
            tokenStore.removeAllTokens()
            appLaunchCounter.increase()
            rootViewState.transitionToRootViewState(.onboarding)
            return
        }

        @InjectService var accountManager: AccountManager

        await accountManager.loadAccounts()
    }
}

#Preview {
    PreloadingView()
        .environmentObject(RootViewState.previewPreloading)
}
