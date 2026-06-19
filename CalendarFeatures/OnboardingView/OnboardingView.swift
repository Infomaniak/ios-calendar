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

import CalendarResources
import InfomaniakOnboarding
import SwiftUI

extension Slide {
    static var onboardingSlides: [Slide] {
        return [
            Slide(
                backgroundImage: UIImage(systemName: "app.background.dotted") ?? UIImage(),
                backgroundImageTintColor: nil,
                content: .illustration(UIImage(systemName: "1.calendar") ?? UIImage()),
                bottomView: OnboardingTextView(text: .oneSlide)
            ),
            Slide(
                backgroundImage: UIImage(systemName: "app.background.dotted") ?? UIImage(),
                backgroundImageTintColor: nil,
                content: .illustration(UIImage(systemName: "2.calendar") ?? UIImage()),
                bottomView: OnboardingTextView(text: .twoSlide)
            ),
            Slide(
                backgroundImage: UIImage(systemName: "app.background.dotted") ?? UIImage(),
                backgroundImageTintColor: nil,
                content: .illustration(UIImage(systemName: "3.calendar") ?? UIImage()),
                bottomView: OnboardingTextView(text: .threeSlide)
            ),
            Slide(
                backgroundImage: UIImage(systemName: "app.background.dotted") ?? UIImage(),
                backgroundImageTintColor: nil,
                content: .illustration(UIImage(systemName: "4.calendar") ?? UIImage()),
                bottomView: OnboardingTextView(text: .fourSlide)
            )
        ]
    }
}

public struct OnboardingView: View {
    @StateObject private var loginHandler = LoginHandler()
    @State private var selection = 0

    public init() {}

    public var body: some View {
        CarouselView(slides: Slide.onboardingSlides, selectedSlide: $selection) { _ in
            OnboardingBottomButtonsView(
                loginHandler: loginHandler,
                selection: $selection,
                slideCount: Slide.onboardingSlides.count
            )
        }
        .background(Color.secondary)
        .ignoresSafeArea()
        .loginErrorAlert(loginHandler: loginHandler)
    }
}

#Preview {
    OnboardingView()
}
