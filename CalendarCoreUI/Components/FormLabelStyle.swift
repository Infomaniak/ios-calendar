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
import SwiftUI

public struct FormLabelStyle: LabelStyle {
    @Environment(\.esdsTheme) private var theme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: IKPadding.mini) {
            configuration.icon
                .frame(width: IKIconSize.large.rawValue, height: IKIconSize.large.rawValue)
                .foregroundStyle(theme.color.contentSecondary)
                .accessibilityHidden(true)

            configuration.title
                .foregroundStyle(theme.color.contentPrimary)
        }
    }
}

public extension LabelStyle where Self == FormLabelStyle {
    static var formLabel: FormLabelStyle {
        FormLabelStyle()
    }
}
