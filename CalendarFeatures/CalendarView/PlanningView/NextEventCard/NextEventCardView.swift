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

enum AnimationHelper {
    static func lerp(a: Double, b: Double, t: Double) -> Double {
        return a * (1 - t) + b * t
    }
}

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
    @State private var buttonSize = CGSize.zero

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
                .animateHide(progress: progress, fullHeight: 12)
                .padding(.bottom, lerp(a: 0, b: 12))
                .padding(.trailing, lerp(a: 0, b: buttonSize.width + 4))
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
                            .animateHide(progress: progress, fullHeight: 16)
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
                        .animateHide(progress: progress, fullHeight: 16)
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
                        .animateHide(progress: progress, fullHeight: 16)
                        .padding(.top, lerp(a: 0, b: 4))
                    }
                }
                .font(.caption2.bold())
            }

            HStack {
                if !event.attendees.isEmpty {
                    NextEventCardAvatarStackView(attendees: event.attendees, progression: progress)
                }

                // We keep this button in the view hierarchy to reserve space
                NextEventCardButton(event: event, progress: 0)
                    .opacity(0)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .animateHide(progress: progress, fullHeight: max(NextEventCardAvatarStackView.height, buttonSize.height))
            .padding(.top, lerp(a: 0, b: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            NextEventCardButtonGeometryView(size: $buttonSize, event: event, progress: progress)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, lerp(a: 8, b: 16))
        .cardBackground(radius: 24)
    }

    private func lerp(a: Double, b: Double) -> Double {
        return AnimationHelper.lerp(a: a, b: b, t: progress)
    }
}

private extension View {
    func animateHide(progress: Double, fullHeight: CGFloat) -> some View {
        self
            .opacity(AnimationHelper.lerp(a: 0, b: 1, t: progress))
            .frame(height: AnimationHelper.lerp(a: 0, b: fullHeight, t: progress))
            .clipped()
            .blur(radius: AnimationHelper.lerp(a: 4, b: 0, t: progress))
    }

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
            .padding(.top, 32)

        Spacer()

        Slider(value: $progress, in: 0 ... 1)
            .padding()
    }
    .padding()
}
