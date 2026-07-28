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

public struct EventDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    private let event: CalendarCoreUI.UIEvent

    public init(
        event: CalendarCoreUI.UIEvent
    ) {
        self.event = event
    }

    public var body: some View {
        NavigationStack {
            Form {
                EventSectionView(event: event)
                CalendarSectionView(event: event)
                ParticipantsSectionView(event: event)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close, action: dismiss.callAsFunction)
                    } else {
                        Button(action: dismiss.callAsFunction) {
                            Label(CalendarResourcesStrings.closeLabel, systemImage: "xmark")
                        }
                    }
                }
            }
            .navigationTitle(CalendarResourcesStrings.eventTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    EventDetailsView(event: CalendarCoreUI.UIEvent.preview)
}
