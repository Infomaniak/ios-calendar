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

import CalendarResources
import SwiftUI

public struct ColorSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown
    ]

    @Binding var selection: Color

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 16)]

    public init(selection: Binding<Color>) {
        _selection = selection
    }

    public var body: some View {
        NavigationStack {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(colors, id: \.self) { paletteColor in
                    Button {
                        selection = paletteColor
                        dismiss()
                    } label: {
                        Circle()
                            .fill(paletteColor)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if paletteColor == selection {
                                    Circle()
                                        .stroke(.primary, lineWidth: 2)
                                        .padding(-4)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle(CalendarResourcesStrings.eventColorLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CalendarResourcesStrings.closeLabel) { dismiss() }
                }
            }
        }
    }
}
