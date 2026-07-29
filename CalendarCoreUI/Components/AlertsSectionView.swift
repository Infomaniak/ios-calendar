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
import InfomaniakCoreSwiftUI
import SwiftUI

public struct AlertsSectionView: View {
    let isEditableView: Bool
    let event: CalendarCoreUI.UIEvent?
    @State private var alarmOffsets: [AlarmOffset]

    public init(
        event: CalendarCoreUI.UIEvent?,
        isEditableView: Bool = false
    ) {
        self.event = event
        self.isEditableView = isEditableView
        _alarmOffsets = State(initialValue: (event?.alarms)?.map {
            AlarmOffset(trigger: $0.trigger)
        } ?? [])
    }

    public var body: some View {
        if !alarmOffsets.isEmpty {
            Section {
                ForEach(alarmOffsets.indices, id: \.self) { index in
                    if isEditableView {
                        Picker("Alarm \(index + 1)", selection: $alarmOffsets[index]) {
                            ForEach(AlarmOffset.allCases) { offset in
                                Text(offset.rawValue).tag(offset)
                            }
                        }
                    } else {
                        HStack {
                            Text("Alarm \(index + 1)")

                            Text(AlarmOffset.allCases.first { $0 == alarmOffsets[index] }?.rawValue ?? "")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }

            } header: {
                Text("Alerts")
            }
        }
    }
}
