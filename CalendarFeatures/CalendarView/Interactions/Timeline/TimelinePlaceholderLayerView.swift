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

struct TimelinePlaceholderLayerView: View {
    @Environment(\.calendar) private var calendar

    @Environment(EventInteractionModel.self) private var interaction

    let date: Date
    let pointsPerHour: CGFloat

    private var placeholder: EventPlaceholder? {
        guard let placeholder = interaction.placeholder,
              !placeholder.isAllDay,
              calendar.isDate(placeholder.start, inSameDayAs: date)
        else { return nil }

        return placeholder
    }

    var body: some View {
        ZStack(alignment: .top) {
            if let placeholder {
                let startOfDay = calendar.startOfDay(for: date)
                let height = CGFloat(placeholder.duration / 3600) * pointsPerHour
                let minimumHeight = CGFloat(EventInteractionModel.snapInterval / 3600) * pointsPerHour

                EventPlaceholderView(placeholder: placeholder)
                    .frame(height: max(height, minimumHeight) - 2 * DayContentView.Constants.layoutVerticalSpacing)
                    .offset(
                        y: CGFloat(placeholder.start.timeIntervalSince(startOfDay) / 3600) * pointsPerHour
                            + DayContentView.Constants.layoutVerticalSpacing
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.snappy(duration: 0.2), value: placeholder)
    }
}
