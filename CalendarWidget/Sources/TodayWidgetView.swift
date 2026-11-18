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

import ESDSCalendar
import ESDSFoundation
import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    @Environment(\.esdsTheme) private var theme

    private var weekdayText: Text {
        Text(.currentDate, format: .dateTime.weekday(.abbreviated))
            .foregroundStyle(theme.color.contentBrand)
    }

    private var monthText: Text {
        Text(.currentDate, format: Date.FormatStyle(capitalizationContext: .beginningOfSentence).month(.abbreviated))
            .foregroundStyle(theme.color.contentSecondary)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("\(weekdayText) \(monthText)")
                .font(.title)

            Text(.currentDate, format: .dateTime.day())
                .font(.system(size: 100, weight: .medium))
                .foregroundStyle(theme.color.contentPrimary)
        }
        .lineLimit(1)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.5)
        .containerBackground(for: .widget) {
            theme.color.backgroundElevationSurface
        }
    }
}

#Preview(as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now)
}
