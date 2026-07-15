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
            static let minimum: CGFloat = 20
            static let `default`: CGFloat = 60
            static let maximum: CGFloat = 100
        }
    }

    @Environment(\.esdsTheme) private var theme

    @ScaledMetric private var pointsPerHour = Constants.PointsPerHour.default

    let date: Date

    private var hours: [Int] {
        let rangeOfHours = Calendar.current.range(of: .hour, in: .day, for: date) ?? 0 ..< 24
        return Array(rangeOfHours)
    }

    private var viewHeight: CGFloat {
        return CGFloat(hours.count - 1) * pointsPerHour + 1
    }

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            ScrollView {
                ZStack {
                    Canvas { context, size in
                        var indexedSymbols = [Int: GraphicsContext.ResolvedSymbol]()
                        var largestSymbolSize: CGSize = .zero
                        for hour in hours {
                            guard let symbol = context.resolveSymbol(id: hour) else {
                                continue
                            }
                            indexedSymbols[hour] = symbol

                            if symbol.size.width > largestSymbolSize.width || symbol.size.height > largestSymbolSize.height {
                                largestSymbolSize = symbol.size
                            }
                        }

                        for hour in hours {
                            let yHourOffset = largestSymbolSize.height / 2
                            let xHourOffset = largestSymbolSize.width + 16

                            let yPosition = CGFloat(hour) * pointsPerHour + yHourOffset
                            context.stroke(
                                Path(CGRect(x: xHourOffset, y: yPosition, width: size.width, height: 1)),
                                with: .color(.gray.opacity(0.3))
                            )

                            if let hourSymbol = indexedSymbols[hour] {
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
                        ForEach(hours, id: \.self) { hour in
                            Text("\(hour):00")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.color.textSecondary)
                                .tag(hour)
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
