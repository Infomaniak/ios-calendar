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
import ESDSSymbols
import Foundation
import SwiftUI

private struct TimeZoneItem: Identifiable {
    var id: String {
        timeZone.identifier
    }

    let timeZone: TimeZone

    let displayName: String
    let genericName: String?
    let utcOffset: String

    init(timeZone: TimeZone, referenceDate: Date) {
        self.timeZone = timeZone
        displayName = timeZone.formatted(.timeZone(.displayName))
        genericName = timeZone.localizedName(for: .generic, locale: .current)
        utcOffset = timeZone.formatted(.timeZone(.utcOffset(at: referenceDate)))
    }

    func matches(_ query: String) -> Bool {
        return timeZone.identifier.localizedStandardContains(query)
            || displayName.localizedStandardContains(query)
            || genericName?.localizedStandardContains(query) == true
            || utcOffset.localizedStandardContains(query)
    }
}

private struct TimeZoneRow: View {
    let item: TimeZoneItem

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.displayName)
                if let genericName = item.genericName {
                    Text(genericName)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.utcOffset)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}

public struct TimeZoneListView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var items: [TimeZoneItem]?
    @State private var search = ""

    @Binding private var timeZone: TimeZone

    private let referenceDate: Date

    private var visibleItems: [TimeZoneItem] {
        guard let items else { return [] }

        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }

        return items.filter { $0.matches(query) }
    }

    public init(timeZone: Binding<TimeZone>, referenceDate: Date) {
        _timeZone = timeZone
        self.referenceDate = referenceDate
    }

    public var body: some View {
        List(visibleItems) { item in
            Button {
                timeZone = item.timeZone
                dismiss()
            } label: {
                TimeZoneRow(item: item)
            }
        }
        .overlay {
            if items == nil {
                ProgressView()
            } else if visibleItems.isEmpty && !search.isEmpty {
                ContentUnavailableView {
                    Label(CalendarResourcesStrings.emptyStateNoTimeZone, symbol: ESDSSymbols.listMagnifyingGlass)
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle(CalendarResourcesStrings.timeZoneLabel)
        .toolbarTitleDisplayMode(.inline)
        .foregroundStyle(.primary)
        .task {
            items = await Self.loadItems(referenceDate: referenceDate)
        }
    }

    @concurrent
    private static func loadItems(referenceDate: Date) async -> [TimeZoneItem] {
        TimeZone.knownTimeZoneIdentifiers
            .compactMap { TimeZone(identifier: $0) }
            .map { TimeZoneItem(timeZone: $0, referenceDate: referenceDate) }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }
}

#Preview {
    NavigationStack {
        TimeZoneListView(timeZone: .constant(.current), referenceDate: .now)
    }
}
