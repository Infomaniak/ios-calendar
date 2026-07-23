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
import ESDSFoundation
import SwiftUI

struct DayTimelineView: View {
    @Environment(\.esdsTheme) private var theme

    let date: Date
    let pointsPerHour: CGFloat
    let leadingOffset: CGFloat

    enum Constants {
        static let labelSpacing: CGFloat = 16
    }

    static func leadingOffset(for hourMarks: [Date]) -> CGFloat {
        let font = UIFont.systemFont(
            ofSize: UIFont.scaledFontSize(.caption2, size: 11, weight: .semibold),
            weight: .semibold
        )
        let largestLabelWidth = hourMarks
            .map { mark in
                mark.formatted(.dateTime.hour().minute()).size(withAttributes: [.font: font]).width
            }
            .max() ?? CGFloat.zero

        return largestLabelWidth.rounded(.up) + Constants.labelSpacing
    }

    private var hourMarks: [Date] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let startOfNextDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        var marks = [Date]()
        var currentMark = startOfDay
        while currentMark < startOfNextDay {
            marks.append(currentMark)
            guard let nextMark = Calendar.current.date(byAdding: .hour, value: 1, to: currentMark) else { break }
            currentMark = nextMark
        }

        marks.append(startOfNextDay)

        return marks
    }

    var body: some View {
        TimelineView(.everyMinute) { _ in
            Canvas { context, size in
                let labelAreaWidth = leadingOffset - Constants.labelSpacing

                for (index, mark) in hourMarks.enumerated() {
                    guard let hourSymbol = context.resolveSymbol(id: mark) else { continue }

                    let yPosition = CGFloat(index) * pointsPerHour + hourSymbol.size.height / 2
                    context.stroke(
                        Path(CGRect(x: leadingOffset, y: yPosition, width: size.width, height: 1)),
                        with: .color(.gray.opacity(0.3))
                    )

                    context.draw(
                        hourSymbol,
                        in: CGRect(
                            x: (labelAreaWidth - hourSymbol.size.width) / 2,
                            y: CGFloat(index) * pointsPerHour,
                            width: hourSymbol.size.width,
                            height: hourSymbol.size.height
                        )
                    )
                }
            } symbols: {
                ForEach(hourMarks, id: \.self) { mark in
                    Text(mark, format: .dateTime.hour().minute())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.color.textSecondary)
                        .tag(mark)
                }
            }
        }
    }
}

#Preview {
    DayTimelineView(date: .now, pointsPerHour: 50, leadingOffset: 50)
}
