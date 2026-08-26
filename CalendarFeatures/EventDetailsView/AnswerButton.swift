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
import ESDSFoundation
import SwiftUI

struct AnswerButton: View {
    @Environment(\.esdsTheme) private var theme

    let answer: UIParticipationStatus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: IKPadding.micro) {
                answer.icon
                Text(answer.buttonTitle)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, IKPadding.medium)
            .padding(.vertical, IKPadding.mini)
            .adaptiveGlass()
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var foregroundColor: Color {
        switch answer {
        case .accepted:
            isSelected ? .green : theme.color.contentPrimary
        case .declined:
            isSelected ? .red : theme.color.contentPrimary
        case .tentative:
            isSelected ? .gray : theme.color.contentPrimary
        default:
            theme.color.contentPrimary
        }
    }
}

public extension UIParticipationStatus {
    var icon: Image {
        switch self {
        case .accepted: CalendarResourcesAsset.Images.circleCheck.swiftUIImage
        case .declined: CalendarResourcesAsset.Images.circleCross.swiftUIImage
        case .tentative: CalendarResourcesAsset.Images.circleQuestion.swiftUIImage
        case .needsAction: CalendarResourcesAsset.Images.clock.swiftUIImage
        }
    }

    var buttonTitle: String {
        switch self {
        case .accepted: CalendarResourcesStrings.buttonYes
        case .declined: CalendarResourcesStrings.buttonNo
        case .tentative: CalendarResourcesStrings.buttonMaybe
        default:
            ""
        }
    }
}

struct AdaptiveGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive())
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

extension View {
    func adaptiveGlass() -> some View {
        modifier(AdaptiveGlassModifier())
    }
}
