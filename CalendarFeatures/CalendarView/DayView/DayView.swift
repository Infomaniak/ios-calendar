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

struct DayView: View {
    enum Constants {
        enum PointsPerHour {
            static let minimum: CGFloat = 30
            static let `default`: CGFloat = 60
            static let maximum: CGFloat = 100
        }
    }

    @Environment(\.esdsTheme) private var theme

    @ScaledMetric private var pointsPerHour = Constants.PointsPerHour.default

    let date: Date

    private var verticalOffset: CGFloat {
        return UIFont.scaledFontSize(.caption2, size: 11)
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

    private var viewHeight: CGFloat {
        return CGFloat(hourMarks.count - 1) * pointsPerHour + verticalOffset * 2
    }

    var body: some View {
        TimelineView(.everyMinute) { _ in
            ScrollView {
                ZStack {
                    TimelineView(.everyMinute) { _ in
                        Canvas { context, size in
                            var indexedSymbols = [Date: GraphicsContext.ResolvedSymbol]()
                            var largestSymbolSize: CGSize = .zero
                            for mark in hourMarks {
                                guard let symbol = context.resolveSymbol(id: mark) else {
                                    continue
                                }
                                indexedSymbols[mark] = symbol

                                if symbol.size.width > largestSymbolSize.width || symbol.size.height > largestSymbolSize.height {
                                    largestSymbolSize = symbol.size
                                }
                            }

                            for (index, mark) in hourMarks.enumerated() {
                                let yHourOffset = largestSymbolSize.height / 2
                                let xHourOffset = largestSymbolSize.width + 16

                                let yPosition = CGFloat(index) * pointsPerHour + yHourOffset
                                context.stroke(
                                    Path(CGRect(x: xHourOffset, y: yPosition, width: size.width, height: 1)),
                                    with: .color(.gray.opacity(0.3))
                                )

                                if let hourSymbol = indexedSymbols[mark] {
                                    let centeredXPosition = largestSymbolSize.width / 2 - hourSymbol.size.width / 2

                                    context.draw(
                                        hourSymbol,
                                        in: CGRect(
                                            x: centeredXPosition,
                                            y: yPosition - yHourOffset,
                                            width: hourSymbol.size.width,
                                            height: hourSymbol.size.height
                                        )
                                    )
                                }
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

                    // EventsView goes here
                }
                .frame(height: viewHeight)
            }
            .contentMargins(IKPadding.medium, for: .scrollContent)
        }
    }
}

#Preview {
    DayView(date: .now)
}
