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

import CalendarCoreUI
import CalendarResources
import DesignSystem
import InfomaniakCoreSwiftUI
import SwiftUI

enum OnboardingText {
    case oneSlide
    case twoSlide
    case threeSlide
    case fourSlide

    var title: String {
        switch self {
        case .oneSlide:
            "onboardingOneTitle"
        case .twoSlide:
            "onboardingTwoTitle"
        case .threeSlide:
            "onboardingThreeTitle"
        case .fourSlide:
            "onboardingFourTitle"
        }
    }

    var subtitle: AttributedString {
        var result = AttributedString(template(argument))
        result.font = .CalendarFont.title

        if let argumentRange = result.range(of: argument) {
            result[argumentRange].font = .CalendarFont.title
        }

        return result
    }

    private var argument: String {
        switch self {
        case .oneSlide:
            "onboardingOneSubtitleArgument"
        case .twoSlide:
            "onboardingTwoSubtitleArgument"
        case .threeSlide:
            "onboardingThreeSubtitleArgument"
        case .fourSlide:
            "onboardingFourSubtitleArgument"
        }
    }

    private var template: (_ argument: Any) -> String {
        switch self {
        case .oneSlide:
            return { _ in "onboardingOneSubtitleTemplate" }
        case .twoSlide:
            return { _ in "onboardingTwoSubtitleTemplate" }
        case .threeSlide:
            return { _ in "onboardingThreeSubtitleTemplate" }
        case .fourSlide:
            return { _ in "onboardingFourSubtitleTemplate" }
        }
    }
}

struct OnboardingTextView: View {
    let text: OnboardingText

    var body: some View {
        VStack(spacing: IKPadding.mini) {
            Text(text.title)
                .font(.CalendarFont.specificTitleLight)

            Text(text.subtitle)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    OnboardingTextView(text: .oneSlide)
    OnboardingTextView(text: .twoSlide)
    OnboardingTextView(text: .threeSlide)
    OnboardingTextView(text: .fourSlide)
}
