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

struct MonthDayEventsPopoverButton: View {
    @Environment(\.esdsTheme) private var theme

    @State private var isShowingDayEventsView = false

    let day: Date
    let hiddenEventCount: Int
    let events: [UIEventSummary]

    var body: some View {
        Button {
            isShowingDayEventsView = true
        } label: {
            Text(verbatim: "+\(hiddenEventCount)")
                .font(.caption.bold())
                .foregroundStyle(theme.color.contentSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingDayEventsView) {
            MonthDayEventsView(day: day, events: events)
                .selfSizingPopover(idealWidth: 320)
                .presentationCompactAdaptation(.popover)
        }
    }
}

struct MonthDayEventsView: View {
    @Environment(\.esdsTheme) private var theme

    let day: Date
    let events: [UIEventSummary]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IKPadding.micro) {
                Text(day, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.headline)
                    .foregroundStyle(theme.color.contentPrimary)
                    .padding(.bottom, value: .mini)
                    .accessibilityAddTraits(.isHeader)

                ForEach(events) { event in
                    AllDayEventButton(event: event)
                }
            }
            .padding(value: .medium)
        }
    }
}

#Preview {
    MonthDayEventsView(day: .now, events: [.preview, .shortPreview, .mediumPreview, .longPreview])
        .environment(MainViewState())
}
