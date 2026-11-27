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
import CalendarResources
import ESDSFoundation
import SwiftUI

struct CustomRecurrenceSummaryRow: View {
    private struct DescriptionKey: Hashable {
        // periphery:ignore - Used for Hashable conformance
        let recurrence: CustomRecurrence?
        // periphery:ignore - Used for Hashable conformance
        let startDate: Date
    }

    @Environment(\.esdsTheme) private var theme

    @State private var recurrenceDescription: String?

    let recurrence: CustomRecurrence?
    let startDate: Date
    let describe: @MainActor () async -> String?

    var body: some View {
        Text(recurrenceDescription ?? EventRecurrence.custom.label)
            .font(.subheadline)
            .foregroundStyle(theme.color.contentSecondary)
            .task(id: DescriptionKey(recurrence: recurrence, startDate: startDate)) {
                recurrenceDescription = await describe()
            }
    }
}
