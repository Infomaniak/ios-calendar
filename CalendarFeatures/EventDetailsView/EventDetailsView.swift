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
import CalendarCreateEditEventView
import CalendarResources
import DesignSystem
import SwiftUI

public struct EventDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var path: NavigationPath = .init()

    private let event: CalendarCoreUI.UIEvent
    @State private var color: Color
    @State private var calendarColor: Color
    @State private var isColorPickerPresented = false

    public init(
        event: CalendarCoreUI.UIEvent
    ) {
        self.event = event
        _color = State(initialValue: Color(event.colors.onDatavizContainer))
        _calendarColor = State(initialValue: Color(.gray))
    }

    public var body: some View {
        NavigationStack(path: $path) {
            Form {
                EventSectionView(
                    event: event,
                    color: $color,
                    calendarColor: $calendarColor,
                    isColorPickerPresented: $isColorPickerPresented
                )
                CalendarSectionView(event: event, calendarColor: $calendarColor)
                AlertsSectionView(event: event)
                ParticipantsSectionView(event: event)
            }
            .navigationDestination(for: CalendarCoreUI.UIEvent.self) { event in
                CreateEditEventView(event: event)
            }
            .navigationTitle(CalendarResourcesStrings.eventTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isColorPickerPresented) {
                ColorSelectionView(selection: $color)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
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
                if event.canEdit {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            path.append(event)
                        } label: {
                            Text("Edit")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    EventDetailsView(event: CalendarCoreUI.UIEvent.preview)
}
