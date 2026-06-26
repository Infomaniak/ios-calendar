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
import SwiftUI

struct CalendarListContentView: View {
    @Environment(\.calendarAccounts) private var calendarAccounts
    @State private var expandedAccounts: Set<Int> = []
    let calendars: [UICalendar]

    var body: some View {
        ForEach(calendarAccounts) { account in
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
                    ForEach(calendarsFor(account: account)) { calendar in
                        HStack {
                            Circle()
                                .fill(calendar.color)
                                .frame(width: 8, height: 8)
                            Text(calendar.displayName)
                        }
                    }
                } label: {
                    AccountCellView(user: account.user)
                }
            }
        }
    }

    private func calendarsFor(account: CalendarAccount) -> [UICalendar] {
        calendars.filter { $0.accountId == account.id }
    }
}

#Preview {
    CalendarListContentView(calendars: [.preview])
}
