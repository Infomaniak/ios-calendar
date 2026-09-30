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

import CalendarCore
import ESDSFoundation
import Foundation
import SwiftUI

public struct AlarmRowView: View {
    @Environment(\.esdsTheme) private var theme

    private let labelText: String
    private let action: UIAlarmAction

    public init(alarm: UIEventAlarm) {
        labelText = alarm.label
        action = alarm.action
    }

    public init(alarmDraft: EventAlarmDraft) {
        labelText = alarmDraft.label
        action = alarmDraft.action
    }

    public var body: some View {
        LabeledContent {
            Text(labelText)
                .foregroundStyle(theme.color.contentSecondary)
        } label: {
            AlarmActionLabel(action: action)
        }
    }
}

public struct AlarmActionLabel: View {
    private let action: UIAlarmAction

    public init(action: UIAlarmAction) {
        self.action = action
    }

    public var body: some View {
        Label(action.label, symbol: action.icon)
            .labelStyle(.formLabel)
    }
}
