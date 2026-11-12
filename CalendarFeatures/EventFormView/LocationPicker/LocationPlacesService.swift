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
import Foundation
@preconcurrency import MapKit

struct LocationPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String

    var location: EventLocation {
        if address.isEmpty { return .place(text: name) }
        if address == name || address.hasPrefix("\(name),") { return .place(text: address) }
        return .place(text: "\(name), \(address)")
    }
}

protocol LocationPlacesSearching: Sendable {
    func search(query: String) async throws -> [LocationPlace]
}

struct LocationPlacesService: LocationPlacesSearching {
    func search(query: String) async throws -> [LocationPlace] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        let search = MKLocalSearch(request: request)
        let response = try await withTaskCancellationHandler {
            try await search.start()
        } onCancel: {
            search.cancel()
        }
        try Task.checkCancellation()
        return response.mapItems.prefix(3).compactMap { item in
            let name = item.name ?? query
            let address = item.placemark.title ?? ""
            let coordinate = item.placemark.coordinate
            let id = "\(name)|\(coordinate.latitude)|\(coordinate.longitude)"
            return LocationPlace(id: id, name: name, address: address)
        }
    }
}
