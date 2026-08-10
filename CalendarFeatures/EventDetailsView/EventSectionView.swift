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

struct EventSectionView: View {
    @Environment(\.esdsTheme) private var theme
    let event: CalendarCoreUI.UIEvent

    private let title: String

    @Binding private var color: Color
    @Binding private var calendarColor: Color

    @Binding private var isColorPickerPresented: Bool

    init(
        event: CalendarCoreUI.UIEvent,
        color: Binding<Color> = .constant(.gray),
        calendarColor: Binding<Color> = .constant(.gray),
        isColorPickerPresented: Binding<Bool>
    ) {
        self.event = event
        title = event.title
        _color = color
        _calendarColor = calendarColor
        _isColorPickerPresented = isColorPickerPresented
    }

    var body: some View {
        HStack {
            Button {
                // TODO: After when edit view change isColorPickerPresented value
            } label: {
                RoundedRectangle(cornerRadius: IKRadius.small)
                    .fill(color)
                    .frame(width: IKIconSize.medium.rawValue, height: IKIconSize.medium.rawValue)
                    .shadow(color: .black.opacity(0.25), radius: IKRadius.small, x: 0, y: 0)
                    .overlay {
                        RoundedRectangle(cornerRadius: IKRadius.medium)
                            .stroke(calendarColor, lineWidth: 4)
                            .frame(width: IKIconSize.large.rawValue, height: IKIconSize.large.rawValue)
                    }
                    .padding(.trailing, IKPadding.mini)
            }

            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.body)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    EventSectionView(
        event: UIEvent.preview,
        color: .constant(.blue),
        calendarColor: .constant(.green),
        isColorPickerPresented: .constant(false)
    )
}
