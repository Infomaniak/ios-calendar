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
import SwiftUI

public struct SettingsOptionsListView<Option: SettingsOptionEnum & CaseIterable & Equatable & Hashable>: View
    where Option.AllCases: RandomAccessCollection {
    @Environment(\.esdsTheme) private var theme

    private let navigationTitle: String
    private let header: String?
    private let values: Option.AllCases
    @Binding private var selection: Option

    public init(
        navigationTitle: String,
        header: String? = nil,
        values: Option.AllCases = Option.allCases,
        selection: Binding<Option>
    ) {
        self.navigationTitle = navigationTitle
        self.header = header
        self.values = values
        _selection = selection
    }

    public var body: some View {
        List {
            Section(header: header.map(Text.init)) {
                ForEach(values, id: \.self) { value in
                    Button {
                        selection = value
                    } label: {
                        HStack {
                            if let image = value.image {
                                image
                            }
                            Text(value.title)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if value == selection {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.color.contentPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
