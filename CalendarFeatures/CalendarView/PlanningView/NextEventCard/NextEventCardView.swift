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

final class NextEventCardViewModel: ObservableObject {
    @Published var scrollProgress = 1.0
}

struct NextEventCardView: View {
    @ObservedObject var model: NextEventCardViewModel

    let event = UIEvent.preview

    var body: some View {
        if #available(iOS 17.0, *) {
            NextEventContentCardView(event: event, progress: model.scrollProgress)
        }
    }
}

@available(iOS 17.0, *)
struct NextEventContentCardView: View {
    let event: CalendarCoreUI.UIEvent
    let progress: Double

    private var durationLabel: String {
        return "DANS 1 MINUTE"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(durationLabel.uppercased())
                .font(.system(size: 12))
                .foregroundStyle(.tint)
                .opacity(lerp(a: 0, b: 1))
                .frame(height: lerp(a: 0, b: 12))
                .clipped()
                .blur(radius: lerp(a: 4, b: 0))
                .padding(.bottom, lerp(a: 0, b: 12))
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: lerp(a: 13, b: 16), weight: .bold))
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: lerp(a: 0, b: 4)) {
                        CalendarResourcesAsset.Images.clock.swiftUIImage
                            .resizable()
                            .scaledToFit()
                            .opacity(lerp(a: 0, b: 1))
                            .frame(width: lerp(a: 0, b: 16), height: lerp(a: 0, b: 16))
                            .clipped()
                            .blur(radius: lerp(a: 4, b: 0))
                            .accessibilityHidden(true)

                        Text("08:30 - 09:45")
                    }

                    if let location = event.location {
                        HStack(spacing: 4) {
                            CalendarResourcesAsset.Images.mapPin.swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .accessibilityHidden(true)

                            Text(location)
                        }
                        .opacity(lerp(a: 0, b: 1))
                        .frame(height: lerp(a: 0, b: 16))
                        .clipped()
                        .blur(radius: lerp(a: 4, b: 0))
                        .padding(.top, lerp(a: 0, b: 4))
                    }

                    if event.kMeetLink != nil {
                        HStack(spacing: 4) {
                            CalendarResourcesAsset.Images.productKmeet.swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .accessibilityHidden(true)

                            Text("En Ligne")
                        }
                        .opacity(lerp(a: 0, b: 1))
                        .frame(height: lerp(a: 0, b: 16))
                        .clipped()
                        .blur(radius: lerp(a: 4, b: 0))
                        .padding(.top, lerp(a: 0, b: 4))
                    }
                }
                .font(.caption2.bold())
            }

            HStack {
                NextEventCardButton(event: event)
                    .opacity(0)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .opacity(lerp(a: 0, b: 1))
            .frame(height: lerp(a: 0, b: 16))
            .clipped()
            .blur(radius: lerp(a: 4, b: 0))
            .padding(.top, lerp(a: 0, b: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            NextEventCardButtonGeometryView(event: event, progress: progress)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, lerp(a: 8, b: 16))
        .cardBackground(radius: 24)
    }

    private func lerp(a: Double, b: Double) -> Double {
        return a * (1 - progress) + b * progress
    }
}

private extension View {
    func cardBackground(radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius)
        if #available(iOS 26.0, *) {
            return glassEffect(.regular, in: shape)
        } else {
            return background(.regularMaterial, in: shape)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var progress = 0.0

    VStack {
        NextEventContentCardView(event: .preview, progress: 0)
        NextEventContentCardView(event: .preview, progress: 0.5)
        NextEventContentCardView(event: .preview, progress: 1)

        NextEventContentCardView(event: .preview, progress: progress)
            .padding(.vertical)

        Spacer()

        Slider(value: $progress, in: 0 ... 1)
            .padding()
    }
    .padding()
}
