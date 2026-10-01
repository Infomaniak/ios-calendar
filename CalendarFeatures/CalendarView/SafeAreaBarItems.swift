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

struct SafeAreaBarItem: Identifiable, Equatable {
    let id: AnyHashable
    let version: AnyHashable
    let content: AnyView

    /// AnyView isn't comparable: the host only re-renders when the id or version changes.
    static func == (lhs: SafeAreaBarItem, rhs: SafeAreaBarItem) -> Bool {
        return lhs.id == rhs.id && lhs.version == rhs.version
    }
}

struct SafeAreaBarItemsKey: PreferenceKey {
    static var defaultValue: [SafeAreaBarItem] {
        []
    }

    static func reduce(value: inout [SafeAreaBarItem], nextValue: () -> [SafeAreaBarItem]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    /// Publishes a view to the nearest ancestor that hosts the shared top bar.
    /// - Parameters:
    ///   - id: Identity of the bar item.
    ///   - version: Changes whenever the bar content must be refreshed.
    ///   - isActive: Only active items are shown, e.g. the visible page of a pager.
    func additionalSafeAreaBarView<ID: Hashable, Version: Hashable, BarContent: View>(
        id: ID,
        version: Version,
        isActive: Bool = true,
        @ViewBuilder content: () -> BarContent
    ) -> some View {
        preference(
            key: SafeAreaBarItemsKey.self,
            value: isActive ? [SafeAreaBarItem(id: id, version: version, content: AnyView(content()))] : []
        )
    }
}
