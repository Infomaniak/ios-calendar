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
import MapKit
import SwiftUI

public struct AppleMapsHelper: Sendable {
    private let scheme = "https"
    private let host = "maps.apple.com"

    public init() {}

    public func addressURL(_ address: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [
            URLQueryItem(name: "q", value: address)
        ]
        return components.url
    }

    public func geocode(_ address: String) async -> CLLocationCoordinate2D? {
        do {
            if #available(iOS 26.0, *) {
                guard let request = MKGeocodingRequest(addressString: address) else {
                    return nil
                }

                return try await request.mapItems.first?.location.coordinate
            } else {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.geocodeAddressString(address)

                return placemarks.first?.location?.coordinate
            }
        } catch {
            return nil
        }
    }
}
