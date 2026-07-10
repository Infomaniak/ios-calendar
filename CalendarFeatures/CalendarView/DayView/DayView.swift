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
            static let minimum: CGFloat = 20
            static let `default`: CGFloat = 50
            static let maximum: CGFloat = 80
        }
    }

    @State private var pointsPerHour = Constants.PointsPerHour.default

    let date: Date

    private var hours: [Int] {
        let rangeOfHours = Calendar.current.range(of: .hour, in: .day, for: date) ?? 0..<24
        return Array(rangeOfHours)
    }

    private var viewHeight: CGFloat {
        return CGFloat(hours.count) * pointsPerHour
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.everyMinute) { timeline in
                ScrollView {
                    ZStack {
                        Canvas { context, size in
                            // Draw the timeline background
                        }

                        // EventsView goes here
                    }
                    .frame(height: viewHeight)
                }
            }
        }
    }
}

#Preview {
    DayView(date: .now)
}
