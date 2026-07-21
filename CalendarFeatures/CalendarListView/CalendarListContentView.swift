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
import CalendarCoreUI
import InfomaniakDI
@preconcurrency import MultiplatformCalendar
import SwiftUI

private extension View {
    func checkmarkTransition() -> some View {
        if #available(iOS 26.0, *) {
            return transition(.symbolEffect(.drawOn))
        } else {
            return transition(.opacity)
        }
    }
}

struct CalendarListContentView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts

    @State private var expandedAccounts: Set<Int> = []
    @State private var visibilityOverrides = [String: Bool]()

    let indexedCalendars: [Int: [UICalendar]]

    var body: some View {
        ForEach(Array(calendarAccounts.values)) { account in
            Section {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedAccounts.contains(account.id) },
                        set: { isExpanding in
                            if isExpanding {
                                expandedAccounts.insert(account.id)
                            } else {
                                expandedAccounts.remove(account.id)
                            }
                        }
                    )
                ) {
                    ForEach(indexedCalendars[account.id, default: []]) { calendar in
                        Button {
                            toggleCalendar(calendar: calendar)
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(calendar.color)
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        if isVisible(calendar) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(.white) // TODO: Use a color that contrasts well with the calendar color
                                                .checkmarkTransition()
                                                .animation(.spring(duration: 0.25), value: isVisible(calendar))
                                        }
                                    }
                                    .accessibilityHidden(true)

                                Text(calendar.displayName)
                                    .lineLimit(1)
                                    .foregroundStyle(.foreground)
                            }
                        }
                    }
                } label: {
                    AccountCellView(
                        rawAvatarURL: account.user.avatar,
                        displayName: account.user.displayName,
                        email: account.user.email
                    )
                }
            }
        }
    }

    private func isVisible(_ calendar: UICalendar) -> Bool {
        visibilityOverrides[calendar.id] ?? calendar.isVisible
    }

    private func toggleCalendar(calendar: UICalendar) {
        let previousValue = isVisible(calendar)
        let newValue = !previousValue

        visibilityOverrides[calendar.id] = newValue

        Task {
            @InjectService var calendarSDK: CalendarCoreGraph
            do {
                try await calendarSDK.calendarManager.updateCalendar(
                    calendarId: calendar.id,
                    edit: .init(isVisible: KotlinBoolean(bool: newValue))
                )
            } catch {
                visibilityOverrides[calendar.id] = previousValue
            }
        }
    }
}

#Preview {
    CalendarListContentView(indexedCalendars: [0: [.preview]])
}
