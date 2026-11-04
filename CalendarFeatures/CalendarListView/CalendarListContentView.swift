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
import DesignSystem
import ESDSFoundation
import ESDSSymbols
import InfomaniakDI
@preconcurrency import MultiplatformCalendar
import SwiftUI

struct StoredIds<ID: LosslessStringConvertible & Hashable & Comparable>: RawRepresentable {
    var ids: Set<ID>

    init(ids: Set<ID> = []) {
        self.ids = ids
    }

    init?(rawValue: String) {
        ids = Set(rawValue.split(separator: ",").compactMap { ID(String($0)) })
    }

    var rawValue: String {
        ids.sorted().map { String($0) }.joined(separator: ",")
    }
}

struct CalendarListContentView: View {
    @Environment(\.esdsTheme) private var theme
    @Environment(\.calendarAccounts) private var calendarAccounts

    @SceneStorage("CalendarListExpandedAccounts") private var expandedAccounts = StoredIds<Int>()
    @SceneStorage("CalendarListCollapsedSections") private var collapsedSections = StoredIds<String>()
    @State private var visibilityOverrides = [String: Bool]()

    let sectionsByAccount: [Int: [UICalendarSection]]

    private func isExpandedBinding(for accountId: Int) -> Binding<Bool> {
        Binding(
            get: { expandedAccounts.ids.contains(accountId) },
            set: { isExpanding in
                if isExpanding {
                    expandedAccounts.ids.insert(accountId)
                } else {
                    expandedAccounts.ids.remove(accountId)
                }
            }
        )
    }

    private func isSectionExpandedBinding(for sectionId: String) -> Binding<Bool> {
        Binding(
            get: { !collapsedSections.ids.contains(sectionId) },
            set: { isExpanding in
                if isExpanding {
                    collapsedSections.ids.remove(sectionId)
                } else {
                    collapsedSections.ids.insert(sectionId)
                }
            }
        )
    }

    var body: some View {
        let sortedAccounts = Array(calendarAccounts.values).sorted { $0.id < $1.id }

        ForEach(Array(sortedAccounts.enumerated()), id: \.element.id) { index, account in
            Section {
                DisclosureGroup(
                    isExpanded: isExpandedBinding(for: account.id)
                ) {
                    let sections = sectionsByAccount[account.id, default: []]

                    if sections.count == 1, let section = sections.first {
                        calendarRows(for: section)
                    } else {
                        ForEach(sections) { section in
                            DisclosureGroup(isExpanded: isSectionExpandedBinding(for: section.id)) {
                                calendarRows(for: section)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: IKPadding.medium))
                            } label: {
                                Text(section.organisationName ?? CalendarResourcesStrings.otherCalendarsSectionTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(theme.color.contentSecondary)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: IKPadding.mini, bottom: 0, trailing: 20))
                    }
                } label: {
                    AccountCellView(
                        rawAvatarURL: account.user.avatar,
                        displayName: account.user.displayName,
                        email: account.user.email
                    )
                }
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    0
                }
            } header: {
                if index == 0 {
                    Text(CalendarResourcesStrings.calendarsMenuSectionTitle)
                        .foregroundStyle(theme.color.contentSecondary)
                }
            }
        }
    }

    private func calendarRows(for section: UICalendarSection) -> some View {
        ForEach(section.calendars) { calendar in
            CalendarRowView(calendar: calendar, isVisible: isVisible(calendar)) {
                toggleCalendar(calendar: calendar)
            }
        }
        .listRowSeparator(.hidden)
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
    CalendarListContentView(sectionsByAccount: [0: [.preview]])
}
