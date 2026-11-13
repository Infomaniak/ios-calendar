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

import Foundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
public enum EventPasteboard {
    public static func copy(_ item: EventTransferItem) {
        #if canImport(UIKit)
        let itemProvider = NSItemProvider()
        itemProvider.register(item)
        UIPasteboard.general.itemProviders = [itemProvider]
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let data = try? JSONEncoder().encode(item) {
            pasteboard.setData(data, forType: NSPasteboard.PasteboardType(UTType.calendarEvent.identifier))
        }
        pasteboard.setString(item.plainTextDescription, forType: .string)
        #endif
    }
}
