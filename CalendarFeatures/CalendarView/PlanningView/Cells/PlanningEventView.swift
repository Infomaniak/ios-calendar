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
import CalendarResources
import DesignSystem
import SwiftUI

public extension CalendarCoreUI.UIEvent {
    var additionalDurationHeight: CGFloat {
        let duration = endDate.timeIntervalSince(startDate)
        let durationInMinutes = duration / 60

        guard durationInMinutes > PlanningEventView.UIConstants.minDuration else { return 0 }
        guard durationInMinutes < PlanningEventView.UIConstants.maxDuration else { return PlanningEventView.UIConstants.maxSize }

        let ratio = (durationInMinutes - PlanningEventView.UIConstants.minDuration) /
            (PlanningEventView.UIConstants.maxDuration - PlanningEventView.UIConstants.minDuration)
        return CGFloat(ratio) * PlanningEventView.UIConstants.maxSize
    }
}

struct PlanningEventView: View {
    let event: CalendarCoreUI.UIEvent

    enum UIConstants {
        static let minDuration: CGFloat = 15
        static let maxDuration: CGFloat = 120

        static let maxSize: CGFloat = 50
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(event.startDate ..< event.endDate, format: .eventTimeBounds)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption2)

                Text(event.title)
                    .lineLimit(1)
                    .font(.caption.bold())
            }

            EventIconsView(event: event)
        }
        .padding(.bottom, event.additionalDurationHeight)
        .eventCellStyle(event: event)
    }
}

#Preview {
    VStack {
        PlanningEventView(event: .shortPreview)
        PlanningEventView(event: .mediumPreview)
        PlanningEventView(event: .longPreview)
    }
}
