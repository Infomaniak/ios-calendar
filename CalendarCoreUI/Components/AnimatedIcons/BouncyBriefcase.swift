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

public struct BouncyBriefcase: View {
    @State private var bounceTrigger = false

    let isOpened: Bool
    let lineWidth: CGFloat

    public init(isUnlocked: Bool, lineWidth: CGFloat = 1.6) {
        self.isOpened = isUnlocked
        self.lineWidth = lineWidth
    }

    public var body: some View {
        BriefcaseShape(progress: isOpened ? 1 : 0)
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
                    CubicKeyframe(isOpened ? -7 : 7, duration: 0.12)
                    SpringKeyframe(0, duration: 0.36, spring: .bouncy)
                }
            }
            .animation(.spring(duration: 0.52, bounce: 0.42), value: isOpened)
            .onChange(of: isOpened) {
                bounceTrigger.toggle()
            }
            .accessibilityHidden(true)
    }
}

struct BriefcaseShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let t = max(progress, 0)
        let p = zip(Self.closedFlap, Self.openFlap).map { closed, open in
            CGPoint(x: closed.x + (open.x - closed.x) * t, y: closed.y + (open.y - closed.y) * t)
        }

        var path = Path()

        // Handle
        path.move(to: pt(8, 6))
        path.addLine(to: pt(8, 4))
        path.addCurve(to: pt(10, 2), control1: pt(8, 2.895), control2: pt(8.895, 2))
        path.addLine(to: pt(14, 2))
        path.addCurve(to: pt(16, 4), control1: pt(15.105, 2), control2: pt(16, 2.895))
        path.addLine(to: pt(16, 6))

        let leftTop = Self.y(atX: 2, onCubic: p[11], p[12], p[13], p[14])
        let rightTop = Self.y(atX: 22, onCubic: p[8], p[9], p[10], p[11])
        path.move(to: pt(2, leftTop))
        path.addLine(to: pt(2, 18))
        path.addCurve(to: pt(4, 20), control1: pt(2, 19.105), control2: pt(2.895, 20))
        path.addLine(to: pt(20, 20))
        path.addCurve(to: pt(22, 18), control1: pt(21.105, 20), control2: pt(22, 19.105))
        path.addLine(to: pt(22, rightTop))

        // Flap
        path.move(to: p[0])
        path.addLine(to: p[1]) // top edge = hinge
        path.addCurve(to: p[4], control1: p[2], control2: p[3]) // top-right corner
        path.addLine(to: p[5]) // right side
        path.addCurve(to: p[8], control1: p[6], control2: p[7]) // bottom-right corner
        path.addCurve(to: p[11], control1: p[9], control2: p[10]) // bottom curve, right half
        path.addCurve(to: p[14], control1: p[12], control2: p[13]) // bottom curve, left half
        path.addCurve(to: p[17], control1: p[15], control2: p[16]) // bottom-left corner
        path.addLine(to: p[18]) // left side
        path.addCurve(to: p[21], control1: p[19], control2: p[20]) // top-left corner
        path.closeSubpath()

        // Clasp
        let claspY = 12 + (9.5 - 12) * t
        path.move(to: pt(12, claspY))
        path.addLine(to: pt(12.01, claspY))

        let scale = min(rect.width, rect.height) / 24
        return path.applying(
            CGAffineTransform(scaleX: scale, y: scale)
                .concatenating(CGAffineTransform(translationX: rect.midX - 12 * scale, y: rect.midY - 12 * scale))
        )
    }

    private static let closedFlap: [CGPoint] = [
        pt(4, 6), pt(20, 6),
        pt(21.105, 6), pt(22, 6.895), pt(22, 8),
        pt(22, 13),
        pt(22, 13), pt(22, 13), pt(22, 13),
        pt(19.033, 14.959), pt(15.556, 16.003), pt(12, 16.003),
        pt(8.444, 16.003), pt(4.967, 14.959), pt(2, 13),
        pt(2, 13), pt(2, 13), pt(2, 13),
        pt(2, 8),
        pt(2, 6.895), pt(2.895, 6), pt(4, 6),
    ]

    private static let openFlap: [CGPoint] = [
        pt(4.5, 6), pt(19.5, 6),
        pt(20.35, 6), pt(21.05, 6.42), pt(21.48, 7.2),
        pt(22.7, 9.43),
        pt(23.02, 10.01), pt(22.95, 10.45), pt(22.4, 10.7),
        pt(18.9333, 12.2667), pt(15.4667, 13.05), pt(12, 13.05),
        pt(8.5333, 13.05), pt(5.0667, 12.2667), pt(1.6, 10.7),
        pt(1.05, 10.45), pt(0.98, 10.01), pt(1.3, 9.43),
        pt(2.52, 7.2),
        pt(2.95, 6.42), pt(3.65, 6), pt(4.5, 6),
    ]

    private static func y(atX x: CGFloat, onCubic p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
        func point(_ s: CGFloat) -> CGPoint {
            let u = 1 - s
            let a = u * u * u
            let b = 3 * u * u * s
            let c = 3 * u * s * s
            let d = s * s * s
            let px = a * p0.x + b * p1.x + c * p2.x + d * p3.x
            let py = a * p0.y + b * p1.y + c * p2.y + d * p3.y
            return CGPoint(x: px, y: py)
        }
        let isDecreasing = p3.x < p0.x
        var low: CGFloat = 0
        var high: CGFloat = 1
        for _ in 0 ..< 24 {
            let mid = (low + high) / 2
            if (point(mid).x > x) == isDecreasing { low = mid } else { high = mid }
        }

        return point((low + high) / 2).y
    }
}

private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

#Preview("BouncyBriefcase") {
    @Previewable @State var isUnlocked = true
    VStack {
        BouncyBriefcase(isUnlocked: isUnlocked)
            .frame(width: 48, height: 48)

        Button("Toggle") {
            isUnlocked.toggle()
        }
    }
}

#Preview("BriefcaseShape") {
    @Previewable @State var progress = 0.0
    VStack {
        BriefcaseShape(progress: progress)
            .stroke(
                .foreground,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            .frame(width: 48, height: 48)

        Slider(value: $progress, in: 0 ... 1)
    }
    .padding()
}
