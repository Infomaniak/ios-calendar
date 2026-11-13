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
import InfomaniakDI
import MultiplatformCalendar
import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage(UserDefaults.shared.key(.notificationsEnabled), store: .shared)
    private var isNotificationsEnabled = DefaultPreferences.notificationsEnabled

    @Environment(\.esdsTheme) private var theme
    @Environment(\.calendarAccounts) private var calendarAccounts
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var authorizationStatus: UNAuthorizationStatus?
    @State private var sectionsByAccount = [Int: [UICalendarSection]]()
    @State private var collapsedSectionIds = Set<String>()
    @State private var accountNotificationsEnabled = [Int: Bool]()
    @State private var calendarNotificationStates = [String: UICalendarNotificationState]()

    private var isPermissionDenied: Bool {
        authorizationStatus == .denied
    }

    private var areNotificationsEnabled: Bool {
        isNotificationsEnabled && !isPermissionDenied
    }

    private var sortedAccounts: [CalendarAccount] {
        calendarAccounts.values.sorted { $0.id < $1.id }
    }

    private var notificationsEnabledBinding: Binding<Bool> {
        Binding {
            areNotificationsEnabled
        } set: { isEnabled in
            isNotificationsEnabled = isEnabled
            rescheduleEventAlarmNotifications()
        }
    }

    var body: some View {
        List {
            if isPermissionDenied {
                Section {
                    InformationBlockView(
                        state: .info,
                        text: CalendarResourcesStrings.notificationSettingsPermissionDeniedDescription,
                        actionTitle: CalendarResourcesStrings.buttonOpenSystemSettings,
                        action: openSystemNotificationSettings
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            Section {
                Toggle(CalendarResourcesStrings.notificationSettingsAllowNotificationsLabel, isOn: notificationsEnabledBinding)
                    .toggleStyle(.switch)
                    .disabled(isPermissionDenied)
                    .listRowSeparator(.hidden)
            } header: {
                Text(CalendarResourcesStrings.notificationSettingsSystemSectionTitle)
            }

            if areNotificationsEnabled && !sortedAccounts.isEmpty {
                Section {
                    ForEach(sortedAccounts) { account in
                        Toggle(isOn: accountEnabledBinding(for: account.id)) {
                            Text(account.user.email)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .toggleStyle(.switch)
                        .listRowSeparator(.hidden)
                        .task(id: account.id) {
                            await observeNotificationsEnabled(accountId: account.id)
                        }

                        if isAccountEnabled(account.id) {
                            accountSections(sectionsByAccount[account.id, default: []])
                        }
                    }
                } header: {
                    Text(CalendarResourcesStrings.accountsTitle)
                }
            }
        }
        .navigationTitle(CalendarResourcesStrings.generalSettingsNotificationsLabel)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshAuthorizationStatus()
        }
        .task(id: calendarAccounts) {
            await observeCalendars()
        }
        .task {
            await observeCalendarNotificationStates()
        }

        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            Task {
                await refreshAuthorizationStatus()
            }
        }
    }

    @ViewBuilder
    private func accountSections(_ sections: [UICalendarSection]) -> some View {
        if sections.count == 1, let section = sections.first {
            calendarRows(section: section)
        } else {
            ForEach(sections) { section in
                DisclosureGroup(isExpanded: isSectionExpandedBinding(for: section.id)) {
                    calendarRows(section: section)
                        .listRowLeadingInset()
                } label: {
                    Text(section.organisationName ?? CalendarResourcesStrings.otherCalendarsSectionTitle)
                        .lineLimit(1)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.color.contentSecondary)
                }
            }
            .listRowSeparator(.hidden)
            .listRowLeadingInset(IKPadding.small)
        }
    }

    private func calendarRows(section: UICalendarSection) -> some View {
        ForEach(section.calendars) { calendar in
            NavigationLink {
                CalendarNotificationSettingsView(calendar: calendar, state: notificationState(for: calendar.id))
            } label: {
                CalendarNotificationRowView(
                    calendar: calendar,
                    state: notificationState(for: calendar.id)
                )
            }
            .listRowSeparator(.hidden)
        }
    }

    private func isAccountEnabled(_ accountId: Int) -> Bool {
        accountNotificationsEnabled[accountId, default: true]
    }

    private func accountEnabledBinding(for accountId: Int) -> Binding<Bool> {
        Binding {
            isAccountEnabled(accountId)
        } set: { isEnabled in
            setAccount(accountId, enabled: isEnabled)
        }
    }

    private func setAccount(_ accountId: Int, enabled: Bool) {
        let previousValue = isAccountEnabled(accountId)
        accountNotificationsEnabled[accountId] = enabled

        Task {
            @InjectService var calendarSDK: CalendarCoreGraph
            do {
                try await calendarSDK.calendarManager.updateAccountNotificationsEnabled(
                    accountId: Int64(accountId),
                    enabled: enabled
                )
                rescheduleEventAlarmNotifications()
            } catch {
                accountNotificationsEnabled[accountId] = previousValue
            }
        }
    }

    private func isSectionExpandedBinding(for sectionId: String) -> Binding<Bool> {
        Binding {
            !collapsedSectionIds.contains(sectionId)
        } set: { isExpanded in
            if isExpanded {
                collapsedSectionIds.remove(sectionId)
            } else {
                collapsedSectionIds.insert(sectionId)
            }
        }
    }

    private func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        openURL(url)
    }

    private func refreshAuthorizationStatus() async {
        authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func notificationState(for calendarId: String) -> UICalendarNotificationState {
        calendarNotificationStates[calendarId, default: .enabled]
    }

    private func observeCalendarNotificationStates() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await states in calendarSDK.calendarManager.observeCalendarNotificationStatesByIdValue() {
            let statesById = states as? [String: any CalendarNotificationState] ?? [:]
            calendarNotificationStates = statesById.mapValues { UICalendarNotificationState(state: $0) }
        }
    }

    private func observeCalendars() async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await sections in calendarSDK.calendarManager.observeCalendars() {
            sectionsByAccount = Dictionary(grouping: sections.map { UICalendarSection(section: $0) }, by: \.accountId)
        }
    }

    private func observeNotificationsEnabled(accountId: Int) async {
        @InjectService var calendarSDK: CalendarCoreGraph
        for await isEnabled in calendarSDK.calendarManager.observeAccountNotificationsEnabled(accountId: Int64(accountId)) {
            accountNotificationsEnabled[accountId] = isEnabled.boolValue
        }
    }
}

struct CalendarNotificationRowView: View {
    @Environment(\.esdsTheme) private var theme

    let calendar: UICalendar
    let state: UICalendarNotificationState

    private var stateLabel: String {
        switch state {
        case .enabled, .custom:
            return CalendarResourcesStrings.notificationSettingsEnabledLabel
        case .disabled:
            return CalendarResourcesStrings.notificationSettingsDisabledLabel
        }
    }

    var body: some View {
        HStack(spacing: IKPadding.small) {
            Circle()
                .fill(calendar.color)
                .frame(width: IKIconSize.small.rawValue, height: IKIconSize.small.rawValue)
                .accessibilityHidden(true)

            Text(calendar.displayName)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(theme.color.contentPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(stateLabel)
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(theme.color.contentSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

func rescheduleEventAlarmNotifications() {
    Task {
        @InjectService var eventAlarmNotificationsService: EventAlarmNotificationsService
        await eventAlarmNotificationsService.scheduleNotificationsForEventAlarms()
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
