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

import ESDSFoundation
import SwiftUI

struct TimelineIndicatorView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let date: Date
    let pointsPerHour: CGFloat

    private var elapsedTime: CGFloat {
        let startOfDay = calendar.startOfDay(for: date)
        return date.timeIntervalSince(startOfDay) / 3600
    }

    private var tint: Color {
        theme.color.backgroundDatavizPinkDim1Default
    }

    var body: some View {
        HStack(spacing: theme.spacing.twoXs) {
            Text(date.formatted(DayTimelineView.Constants.dateFormater))
                .font(DayTimelineView.Constants.labelFont)
                .padding(.horizontal, theme.spacing.xs)
                .padding(.vertical, theme.spacing.twoXs)
                .foregroundStyle(theme.color.contentInverse)
                .background(tint, in: .capsule)

            HStack(spacing: 0) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)

                Divider()
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .background(tint)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    TimelineIndicatorView(date: .now, pointsPerHour: 0)
}
