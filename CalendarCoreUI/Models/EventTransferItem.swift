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

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

public extension UTType {
    /// In-app representation of a calendar event, declared in the app's `UTExportedTypeDeclarations`.
    static let calendarEvent = UTType(exportedAs: "com.infomaniak.calendar.event")
}

/// An event moved as data: drag and drop, copy and share.
///
/// Inside the app the full Codable payload is used, other apps only receive a plain text description.
public struct EventTransferItem: Codable, Hashable, Identifiable, Sendable {
    public let occurrenceId: String
    public let title: String
    public let location: String?
    /// Start of the dragged day slice, used to compute the move offset.
    public let startDate: Date
    /// End of the dragged day slice.
    public let endDate: Date
    public let isAllDay: Bool
    public let isRecurring: Bool
    public let canEdit: Bool

    public var id: String {
        return occurrenceId
    }

    public var plainTextDescription: String {
        let dates: String
        if isAllDay {
            let lastDay = max(endDate.addingTimeInterval(-1), startDate)
            dates = (startDate ..< lastDay).formatted(.interval.weekday(.wide).day().month(.wide).year())
        } else {
            dates = (startDate ..< endDate).formatted(.interval.weekday(.wide).day().month(.wide).year().hour().minute())
        }

        return [title, dates, location]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    public init(event: UIEventSummary) {
        occurrenceId = event.occurrenceId
        title = event.title
        location = event.location
        startDate = event.startDate
        endDate = event.endDate
        isAllDay = event.isAllDay
        isRecurring = event.isRecurring
        canEdit = event.canEdit
    }
}

extension EventTransferItem: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .calendarEvent)
            .visibility(.ownProcess)
        ProxyRepresentation(exporting: \.plainTextDescription)
    }
}
