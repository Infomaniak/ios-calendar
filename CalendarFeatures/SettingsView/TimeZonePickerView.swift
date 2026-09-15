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
import CalendarResources
import Foundation
import SwiftUI

public struct TimeZonePickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var timeZones = [TimeZone]()

    @Binding private var selection: TimeZone

    public init(selection: Binding<TimeZone>) {
        _selection = selection
    }

    public var body: some View {
        List(timeZones, id: \.identifier) { timeZone in
            Button {
                selection = timeZone
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(timeZone.formatted(.timeZoneDisplayName))

                        Text("\(currentTime(in: timeZone)) (\(gmtOffset(for: timeZone)))")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if selection.identifier == timeZone.identifier {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .navigationTitle(CalendarResourcesStrings.generalSettingsTimeZoneLabel)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText)
        .task(id: searchText) {
            if !searchText.isEmpty {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch {
                    return
                }
            }

            let searchText = searchText
            let filteredTimeZones = await timeZones(matching: searchText)

            guard !Task.isCancelled else {
                return
            }

            timeZones = filteredTimeZones
        }
    }

    @concurrent
    private func timeZones(matching searchText: String) async -> [TimeZone] {
        TimeZone.knownTimeZoneIdentifiers
            .compactMap(TimeZone.init(identifier:))
            .filter { timeZone in
                guard !searchText.isEmpty else {
                    return true
                }

                return timeZone.formatted(.timeZoneDisplayName).localizedCaseInsensitiveContains(searchText)
                    || timeZone.identifier.localizedCaseInsensitiveContains(searchText)
            }
            .sorted {
                $0.formatted(.timeZoneDisplayName)
                    .localizedStandardCompare($1.formatted(.timeZoneDisplayName)) == .orderedAscending
            }
    }

    private func currentTime(in timeZone: TimeZone) -> String {
        Date.now.formatted(
            Date.FormatStyle(
                date: .omitted,
                time: .shortened,
                locale: .autoupdatingCurrent,
                timeZone: timeZone
            )
        )
    }

    private func gmtOffset(for timeZone: TimeZone) -> String {
        Date.now.formatted(
            Date.FormatStyle(
                date: .omitted,
                time: .omitted,
                locale: .autoupdatingCurrent,
                timeZone: timeZone
            )
            .timeZone(.localizedGMT(.short))
        )
    }
}
