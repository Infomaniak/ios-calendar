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
import SwiftUI

public struct TodayIconView: View {
    public init() {}

    public var body: some View {
        TimelineView(.everyMinute) { timeline in
            DayIconView(date: timeline.date)
        }
    }
}

struct DayIconView: View {
    let date: Date

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(.black, lineWidth: 1.5)
            .overlay {
                Text(date, format: .dateTime.day())
                    .font(.system(size: 64, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.1)
                    .monospacedDigit()
                    .padding(2)
            }
            .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    let calendar = Calendar.current
    let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? .now

    HStack(spacing: IKPadding.medium) {
        ForEach([1, 12, 31], id: \.self) { day in
            DayIconView(date: calendar.date(bySetting: .day, value: day, of: referenceDate) ?? referenceDate)
                .frame(width: 30, height: 30)
        }
    }
}
