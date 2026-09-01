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

public extension View {
    func closeToolbarItem(_ close: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .close, action: close)
                } else {
                    Button(action: close) {
                        Label(CalendarResourcesStrings.closeLabel, systemImage: "xmark")
                    }
                }
            }
        }
    }

    func closeToolbarItem(dismiss: DismissAction) -> some View {
        closeToolbarItem(dismiss.callAsFunction)
    }
}
