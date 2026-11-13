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

struct AnimatedTitleView: View {
    @Environment(\.calendar) private var calendar

    @State private var displayedDate = Date.now
    @State private var isForward = true

    let date: Date
    let isExpanded: Bool
    let showChevron: Bool

    private var dateFormat: Date.FormatStyle {
        if calendar.isDate(date, equalTo: .now, toGranularity: .year) {
            return .dateTime.month(.wide)
        } else {
            return .dateTime.year().month(.wide)
        }
    }

    var body: some View {
        HStack(spacing: IKPadding.mini) {
            Text(displayedDate, format: dateFormat)
                .id(displayedDate)
                .transition(
                    .push(from: isForward ? .bottom : .top)
                )

            if showChevron {
                Image(systemName: "chevron.down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
        }
        .onAppear {
            displayedDate = date
        }
        .onChange(of: date) { oldValue, newValue in
            isForward = newValue > oldValue
            withAnimation(.default.speed(3)) {
                displayedDate = calendar.monthStart(for: newValue)
            }
        }
    }
}

#Preview {
    @Previewable @State var date = Date.now
    VStack(spacing: 32) {
        AnimatedTitleView(date: date, isExpanded: false, showChevron: true)

        HStack {
            Button("Previous Month") {
                date = Calendar.current.date(byAdding: .month, value: -1, to: date) ?? date
            }
            Button("Next Month") {
                date = Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
            }
        }
        .buttonStyle(.borderedProminent)
    }
}
