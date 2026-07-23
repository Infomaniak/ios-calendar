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
import UIKit

struct WeekOrMonthView: View {
    let weekStartDate: Date

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< 7) { dayOffset in
                ZStack {
                    if let dayDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStartDate) {
                        DayCellView(date: dayDate)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    WeekOrMonthView(weekStartDate: Calendar.current.weekStart(for: Date()))
}
