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

import CalendarCoreUI
import CalendarResources
import SwiftUI

struct NextEventCardButtonGeometryView: View {
    @State private var size = CGSize.zero

    let event: CalendarCoreUI.UIEvent
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            NextEventCardButton(event: event)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
                .position(
                    x: proxy.size.width - size.width / 2,
                    y: lerp(a: proxy.size.height / 2, b: proxy.size.height - size.height / 2)
                )
        }
    }

    private func lerp(a: Double, b: Double) -> Double {
        return a * (1 - progress) + b * progress
    }
}

struct NextEventCardButton: View {
    let event: CalendarCoreUI.UIEvent

    enum CallToActionKind {
        case joinKMeetRoom
        case openMap
        case showEventDetails

        var icon: Image {
            switch self {
            case .joinKMeetRoom:
                return CalendarResourcesAsset.Images.productKmeet.swiftUIImage
            case .openMap:
                return CalendarResourcesAsset.Images.mapPin.swiftUIImage
            case .showEventDetails:
                return CalendarResourcesAsset.Images.productCalendar.swiftUIImage
            }
        }

        var label: String {
            switch self {
            case .joinKMeetRoom:
                return "Rejoindre"
            case .openMap:
                return "Itinéraire"
            case .showEventDetails:
                return "Afficher"
            }
        }
    }

    private var kind: CallToActionKind {
        if event.kMeetLink != nil {
            return .joinKMeetRoom
        } else if event.location != nil {
            return .openMap
        } else {
            return .showEventDetails
        }
    }

    var body: some View {
        Button(action: didTapAction) {
            HStack(spacing: 4) {
                kind.icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)

                Text(kind.label)
                    .font(.footnote)
            }
        }
        .buttonStyle(.borderedProminent)
    }

    private func didTapAction() {}
}
