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

public struct TimeZoneListView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var search = ""

    @Binding private var timeZone: TimeZone

    private let referenceDate: Date

    private var visibleTimeZones: [TimeZone] {
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Self.timeZones
        }

        return Self.timeZones
            .filter {
                $0.identifier.localizedCaseInsensitiveContains(search)
                    || $0.formattedIdentifier.localizedCaseInsensitiveContains(search)
                    || $0.localizedName(for: .generic, locale: .current)?.localizedCaseInsensitiveContains(search) == true
                    || $0.utcOffset(at: referenceDate).localizedCaseInsensitiveContains(search)
            }
            .sorted { $0.formattedIdentifier < $1.formattedIdentifier }
    }

    private static let timeZones = TimeZone.knownTimeZoneIdentifiers
        .compactMap(TimeZone.init(identifier:))
        .sorted { $0.formattedIdentifier < $1.formattedIdentifier }

    public init(timeZone: Binding<TimeZone>, referenceDate: Date) {
        _timeZone = timeZone
        self.referenceDate = referenceDate
    }

    public var body: some View {
        List(visibleTimeZones, id: \.identifier) { timeZone in
            Button {
                self.timeZone = timeZone
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(timeZone.formattedIdentifier)
                        if let localizedName = timeZone.localizedName(for: .generic, locale: .current) {
                            Text(localizedName)
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(timeZone.utcOffset(at: referenceDate))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle(CalendarResourcesStrings.timeZoneLabel)
        .toolbarTitleDisplayMode(.inline)
        .foregroundStyle(.primary)
    }
}

#Preview {
    NavigationStack {
        TimeZoneListView(timeZone: .constant(.current), referenceDate: .now)
    }
}
