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

import SwiftUI

public struct CalendarLabel: View {
    let name: String
    let colorIndicator: UIImage

    public init(calendar: UICalendar) {
        name = calendar.displayName

        let size = CGSize(width: 12, height: 12)
        colorIndicator = UIGraphicsImageRenderer(size: size)
            .image { context in
                context.cgContext.setFillColor(UIColor(calendar.color).cgColor)
                context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            }
            .withRenderingMode(.alwaysOriginal)
    }

    public var body: some View {
        HStack {
            Image(uiImage: colorIndicator)
                .accessibilityHidden(true)

            Text(name)
        }
    }
}

#Preview {
    CalendarLabel(calendar: .preview)
}
