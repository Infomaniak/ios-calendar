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
import ESDSFoundation
import ESDSSymbols
import SwiftUI

public extension InformationBlockView {
    enum State: Sendable {
        case info

        var symbol: ESDSSymbols {
            switch self {
            case .info:
                return .circleInfo
            }
        }

        func backgroundColor(theme: ESDSTheme) -> Color {
            switch self {
            case .info:
                return theme.color.backgroundFeedbackInformationDim3
            }
        }

        func borderColor(theme: ESDSTheme) -> Color {
            switch self {
            case .info:
                return theme.color.borderFeedbackInformationDim1
            }
        }

        func contentColor(theme: ESDSTheme) -> Color {
            switch self {
            case .info:
                return theme.color.contentOnFeedbackInformationDim3
            }
        }
    }
}

public struct InformationBlockView: View {
    @Environment(\.esdsTheme) private var theme

    let state: State
    let text: String

    public init(state: State, text: String) {
        self.state = state
        self.text = text
    }

    public var body: some View {
        HStack(spacing: IKPadding.medium) {
            state.symbol.image
                .font(.system(size: IKIconSize.large.rawValue))
                .accessibilityHidden(true)

            Text(text)
                .font(.body)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(state.contentColor(theme: theme))
        .padding(value: .medium)
        .background(state.backgroundColor(theme: theme), in: theme.radius.threeXl)
        .overlay {
            theme.radius.threeXl
                .strokeBorder(state.borderColor(theme: theme), lineWidth: 1)
        }
    }
}

#Preview {
    InformationBlockView(
        state: .info,
        text: "The limit is 100 guests."
    )
    .padding()
}
