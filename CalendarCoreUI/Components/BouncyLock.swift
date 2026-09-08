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

private struct BounceValues {
    var scale = 1.0
    var rotation = 0.0
}

public struct BouncyLock: View {
    @State private var bounceTrigger = false

    let isUnlocked: Bool
    let lineWidth: CGFloat

    public init(isUnlocked: Bool, lineWidth: CGFloat = 1.75) {
        self.isUnlocked = isUnlocked
        self.lineWidth = lineWidth
    }

    public var body: some View {
        LockShape(progress: isUnlocked ? 1 : 0)
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
                    CubicKeyframe((isUnlocked ? -7 : 7), duration: 0.12)
                    SpringKeyframe(0, duration: 0.36, spring: .bouncy)
                }
            }
            .animation(.spring(duration: 0.52, bounce: 0.42), value: isUnlocked)
            .onChange(of: isUnlocked) {
                bounceTrigger.toggle()
            }
            .accessibilityHidden(true)
    }
}

/// LockShape recreates the icons `lock` and `lock-open` from ESDS
private struct LockShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        let origin = CGPoint(
            x: rect.midX - 12 * scale,
            y: rect.midY - 12 * scale
        )
        let transform = CGAffineTransform(
            a: scale, b: 0, c: 0, d: scale,
            tx: origin.x, ty: origin.y
        )

        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: 3, y: 11, width: 18, height: 11),
            cornerSize: CGSize(width: 2, height: 2)
        )

        let t = min(max(progress, 0), 1.15)
        path.move(to: CGPoint(x: 7, y: 11))
        path.addLine(to: CGPoint(x: 7, y: 7))
        addCurve(
            to: point(locked: (8.4645, 3.4645), unlocked: (8.2894, 3.6438), t: t),
            control1: point(locked: (7, 5.6193), unlocked: (6.9988, 5.7602), t: t),
            control2: point(locked: (7.5596, 4.3693), unlocked: (7.4583, 4.5640), t: t),
            to: &path
        )
        addCurve(
            to: point(locked: (12, 2), unlocked: (11.4975, 2.0204), t: t),
            control1: point(locked: (9.3693, 2.5596), unlocked: (9.1205, 2.7236), t: t),
            control2: point(locked: (10.6193, 2), unlocked: (10.2638, 2.1451), t: t),
            to: &path
        )
        addCurve(
            to: point(locked: (15.5355, 3.4645), unlocked: (14.9655, 2.9695), t: t),
            control1: point(locked: (13.3807, 2), unlocked: (12.7312, 1.8958), t: t),
            control2: point(locked: (14.6307, 2.5596), unlocked: (13.9671, 2.2341), t: t),
            to: &path
        )
        addCurve(
            to: point(locked: (17, 7), unlocked: (16.9, 6), t: t),
            control1: point(locked: (16.4404, 4.3693), unlocked: (15.9638, 3.7049), t: t),
            control2: point(locked: (17, 5.6193), unlocked: (16.6533, 4.785), t: t),
            to: &path
        )
        path.addLine(to: point(locked: (17, 11), unlocked: (16.9, 6), t: t))

        return path.applying(transform)
    }

    private func point(locked: (CGFloat, CGFloat), unlocked: (CGFloat, CGFloat), t: CGFloat) -> CGPoint {
        return CGPoint(
            x: locked.0 + (unlocked.0 - locked.0) * t,
            y: locked.1 + (unlocked.1 - locked.1) * t
        )
    }

    private func addCurve(to point: CGPoint, control1: CGPoint, control2: CGPoint, to path: inout Path) {
        path.addCurve(to: point, control1: control1, control2: control2)
    }
}

#Preview("BouncyLock") {
    @Previewable @State var isUnlocked = true
    VStack {
        BouncyLock(isUnlocked: isUnlocked)
            .frame(width: 48, height: 48)

        Button("Toggle") {
            isUnlocked.toggle()
        }
    }
}

#Preview("LockShape") {
    @Previewable @State var progress = 0.0
    VStack {
        LockShape(progress: progress)
            .stroke(
                .foreground,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            .frame(width: 48, height: 48)

        Slider(value: $progress, in: 0 ... 1)
    }
    .padding()
}
