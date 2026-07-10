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

import SwiftUI

struct DayView: View {
    enum Constants {
        enum PointsPerHour {
            static let minimum: CGFloat = 50
            static let `default`: CGFloat = 80
            static let maximum: CGFloat = 150
        }
    }

    @State private var pointsPerHour = Constants.PointsPerHour.default

    let date: Date

    private var hours: [Int] {
        let rangeOfHours = Calendar.current.range(of: .hour, in: .day, for: date) ?? 0..<24
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
                        for hour in hours {
                            let yPosition = CGFloat(hour) * pointsPerHour
                            context.stroke(
                                Path(CGRect(x: 0, y: yPosition, width: size.width, height: 1)),
                                with: .color(.gray.opacity(0.3))
                            )

                            // Add hours
                        }
                    }

                    // EventsView goes here
                }
                .frame(height: viewHeight)
            }
            .contentMargins(16, for: .scrollContent)
        }
    }
}

#Preview {
    DayView(date: .now)
}
