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

import SwiftUI

/// The grid of days displayed by a calendar page, so an event being created can move to any of them.
///
/// Locations are read in `coordinateSpace`, whose origin is the top-leading corner of the page.
struct CreationPage: Equatable {
    static var coordinateSpace: NamedCoordinateSpace {
        return .named("CreationPage")
    }

    let rows: [[Date]]
    let rowHeight: CGFloat
    let leadingInset: CGFloat
    var width: CGFloat = 0

    /// The day under `location`, clamped to the page.
    func day(at location: CGPoint) -> Date? {
        guard let columnCount = rows.first?.count, columnCount > 0, rowHeight > 0 else { return nil }

        let columnWidth = max(width - leadingInset, 0) / CGFloat(columnCount)
        guard columnWidth > 0 else { return nil }

        let row = min(max(Int(location.y / rowHeight), 0), rows.count - 1)
        let column = Int((location.x - leadingInset) / columnWidth)
        let days = rows[row]
        return days[min(max(column, 0), days.count - 1)]
    }
}

extension View {
    /// Declares a page of days that creation gestures of its descendants can move across.
    /// - Parameter rowHeight: Height of a row of days, `.infinity` for a single row like a timeline.
    func creationPage(rows: [[Date]], rowHeight: CGFloat = .infinity, leadingInset: CGFloat = 0) -> some View {
        modifier(CreationPageModifier(rows: rows, rowHeight: rowHeight, leadingInset: leadingInset))
    }
}

extension EnvironmentValues {
    @Entry var creationPage: CreationPage?
}

private struct CreationPageModifier: ViewModifier {
    @State private var width = CGFloat.zero

    let rows: [[Date]]
    let rowHeight: CGFloat
    let leadingInset: CGFloat

    func body(content: Content) -> some View {
        content
            .environment(\.creationPage, CreationPage(rows: rows, rowHeight: rowHeight, leadingInset: leadingInset, width: width))
            .coordinateSpace(CreationPage.coordinateSpace)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { newWidth in
                width = newWidth
            }
    }
}
