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

//
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

struct MonthPlaceholderLayerView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    @Environment(EventInteractionModel.self) private var interaction

    let days: [Date]
    let metrics: MonthGridMetrics

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                ZStack(alignment: .top) {
                    if let placeholder = interaction.placeholder, calendar.isDate(placeholder.start, inSameDayAs: day) {
                        theme.color.borderDatavizGrayDim1
                            .opacity(0.1)

                        EventPlaceholderView(placeholder: placeholder, style: .compact)
                            .frame(height: metrics.laneHeight)
                            .padding(.top, metrics.totalDayNumberHeight)
                            .padding(.horizontal, value: .micro)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.snappy(duration: 0.2), value: interaction.placeholder)
    }
}
