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
import DesignSystem
import ESDSFoundation
import SwiftUI

struct DayTimelineView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.esdsTheme) private var theme

    let date: Date
    let pointsPerHour: CGFloat
    let leadingOffset: CGFloat

    enum Constants {
        static let labelFont = Font.caption2.weight(.semibold)
        static let labelFontSize = UIFont.scaledFontSize(.caption2, size: 11)
        static let labelSpacing: CGFloat = IKPadding.small

        static let dateFormater: Date.FormatStyle = .dateTime.hour().minute()

        static let indexHeight: CGFloat = 0.5
    }

    private var hourMarks: [Date] {
        let startOfDay = calendar.startOfDay(for: date)
        guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        var marks = [Date]()
        var currentMark = startOfDay
        while currentMark < startOfNextDay {
            marks.append(currentMark)
            guard let nextMark = calendar.date(byAdding: .hour, value: 1, to: currentMark) else { break }
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

                    let yPosition = CGFloat(index) * pointsPerHour + DayContentView.Constants.verticalInset
                    var path = Path()
                    path.move(to: CGPoint(x: leadingOffset, y: yPosition - Constants.indexHeight / 2))
                    path.addLine(to: CGPoint(x: size.width, y: yPosition - Constants.indexHeight / 2))
                    context.stroke(path, with: .color(theme.color.borderDim2Default), lineWidth: Constants.indexHeight)

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
                    Text(mark, format: Self.Constants.dateFormater)
                        .font(Self.Constants.labelFont)
                        .foregroundStyle(theme.color.contentSecondary)
                        .tag(mark)
                }
            }
        }
    }
}

#Preview {
    DayTimelineView(date: .now, pointsPerHour: 50, leadingOffset: 50)
}
