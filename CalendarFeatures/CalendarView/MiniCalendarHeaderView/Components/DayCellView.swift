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

private struct TextCenterAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[VerticalAlignment.center]
    }
}

extension VerticalAlignment {
    static let textCenter = VerticalAlignment(TextCenterAlignment.self)
}

struct DayCellView: View {
    static let maxHeight: CGFloat = 48

    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let date: Date
    var isSelected = false
    let eventDots: [Color]

    private var isToday: Bool {
        return calendar.isDateInToday(date)
    }

    private var displayedEventDots: [Color] {
        guard !(isSelected || isToday) else {
            return []
        }
        return eventDots
    }

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(date, format: .dateTime.day())
                .alignmentGuide(.textCenter) { d in d[VerticalAlignment.center] }
            EventDotsView(eventDots: displayedEventDots)
        }
        .padding(value: .micro)
        .monospacedDigit()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .textCenter))
        .frame(height: Self.maxHeight)
        .font(.body.weight(.semibold))
        .foregroundColor(isToday ? theme.color.contentInverse : theme.color.contentPrimary)
        .background {
            if isToday {
                Circle()
                    .fill(.tint)
                    .padding(value: .mini)
            }
        }
        .overlay {
            if isSelected, !isToday {
                Circle()
                    .stroke(.tint)
                    .transition(.scale(scale: 0.5, anchor: .center).combined(with: .opacity))
                    .padding(value: .mini)
            }
        }
        .animation(.default.speed(2.5), value: isSelected)
        .geometryGroup()
    }
}

#Preview {
    HStack {
        DayCellView(date: Date(), eventDots: [])
        DayCellView(date: Date(timeIntervalSinceNow: -86400), isSelected: true, eventDots: [])
    }
}
