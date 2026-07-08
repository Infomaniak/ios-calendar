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
import CalendarCoreUI
import CalendarResources
import SwiftUI

struct NextEventCardButtonGeometryView: View {
    @Binding var size: CGSize

    let event: CalendarCoreUI.UIEvent
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let x = proxy.size.width - size.width / 2
            let y = lerp(a: proxy.size.height / 2, b: proxy.size.height - size.height / 2)

            NextEventCardButton(event: event, progress: progress)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
                .position(x: x, y: y)
                .animation(.spring(duration: 0.25), value: x)
        }
    }

    private func lerp(a: Double, b: Double) -> Double {
        AnimationHelper.lerp(a: a, b: b, t: progress)
    }
}

struct NextEventCardButton: View {
    @State private var isExpanded = false

    let event: CalendarCoreUI.UIEvent
    let progress: Double

    enum CallToActionKind {
        case joinKMeetRoom
        case openMap(String)
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
        } else if  let location = event.location {
            return .openMap(location)
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

                if isExpanded {
                    Text(kind.label)
                        .font(.footnote)
                        .transition(.slide.combined(with: .opacity).combined(with: .scale))
                }
            }
            .geometryGroup()
        }
        .buttonStyle(.borderedProminent)
        .onAppear {
            updateExpandState(progress: progress)
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(duration: 0.25)) {
                updateExpandState(progress: newValue)
            }
        }
    }

    private func didTapAction() {
        switch kind {
        case .joinKMeetRoom:
            // TODO: Join kMeet meeting
            break
        case .openMap(let address):
            guard let url = AppleMapHelper().addressURL(address) else { return }
            UIApplication.shared.open(url)
        case .showEventDetails:
            // TODO: Open event details
            break
        }
    }

    private func updateExpandState(progress: Double) {
        if progress == 1 {
            isExpanded = true
        } else if progress == 0 {
            isExpanded = false
        }
    }
}
