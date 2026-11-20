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

protocol AnimatedIconShape: Shape {
    var progress: CGFloat { get set }

    init(progress: CGFloat)

    func iconPath() -> Path
}

extension AnimatedIconShape {
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        let transform = CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: rect.midX - 12 * scale, y: rect.midY - 12 * scale))
        return iconPath().applying(transform)
    }
}

extension CGPoint {
    func interpolated(to other: CGPoint, progress: CGFloat) -> CGPoint {
        CGPoint(x: x + (other.x - x) * progress, y: y + (other.y - y) * progress)
    }
}

private struct BounceValues {
    var scale = 1.0
    var rotation = 0.0
}

struct BouncyIcon<IconShape: AnimatedIconShape>: View {
    @State private var bounceTrigger = false

    let shape: IconShape.Type
    let isToggled: Bool
    let lineWidth: CGFloat

    var body: some View {
        shape.init(progress: isToggled ? 1 : 0)
            .stroke(.foreground, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .aspectRatio(1, contentMode: .fit)
            .keyframeAnimator(initialValue: BounceValues(), trigger: bounceTrigger) { content, value in
                content
                    .scaleEffect(value.scale)
                    .rotationEffect(.degrees(value.rotation))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.88, duration: 0.1)
                    SpringKeyframe(1, duration: 0.38, spring: .bouncy)
                }
                KeyframeTrack(\.rotation) {
                    CubicKeyframe(isToggled ? -7 : 7, duration: 0.12)
                    SpringKeyframe(0, duration: 0.36, spring: .bouncy)
                }
            }
            .animation(.spring(duration: 0.52, bounce: 0.42), value: isToggled)
            .onChange(of: isToggled) {
                bounceTrigger.toggle()
            }
            .accessibilityHidden(true)
    }
}
