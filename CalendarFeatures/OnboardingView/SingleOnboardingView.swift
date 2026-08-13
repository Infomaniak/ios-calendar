/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import CalendarCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import InfomaniakOnboarding
import SwiftUI

public struct SingleOnboardingView: View {
    @LazyInjectService private var orientationManager: OrientationManageable

    @Environment(\.dismiss) private var dismiss

    @State private var loginHandler = LoginHandler()

    private let slides = [Slide.onboardingSlides.last!]

    public init() {}

    public var body: some View {
        WaveView(slides: slides, selectedSlide: .constant(0), dismissHandler: {
            Task { @MainActor in dismiss() }
        }) { _ in
            OnboardingBottomButtonsView(
                loginHandler: loginHandler,
                selection: .constant(0),
                slideCount: 1
            )
        }
        .ignoresSafeArea()
        .onAppear {
            if UIDevice.current.userInterfaceIdiom == .phone {
                UIDevice.current
                    .setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                orientationManager.setOrientationLock(.portrait)
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
}

#Preview {
    SingleOnboardingView()
}
