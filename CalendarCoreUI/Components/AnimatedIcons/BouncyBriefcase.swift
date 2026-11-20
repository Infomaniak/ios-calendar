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

public struct BouncyBriefcase: View {
    let isOpened: Bool
    let lineWidth: CGFloat

    public init(isOpened: Bool, lineWidth: CGFloat = 1.6) {
        self.isOpened = isOpened
        self.lineWidth = lineWidth
    }

    public var body: some View {
        BouncyIcon(shape: BriefcaseShape.self, isToggled: isOpened, lineWidth: lineWidth)
    }
}

private struct BriefcaseShape: AnimatedIconShape {
    var progress: CGFloat

    func iconPath() -> Path {
        let t = max(progress, 0)
        let p = zip(Self.closedFlap, Self.openFlap).map { closed, open in
            closed.interpolated(to: open, progress: t)
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

        return path
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
        pt(2, 6.895), pt(2.895, 6), pt(4, 6)
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
        pt(2.95, 6.42), pt(3.65, 6), pt(4.5, 6)
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

private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: x, y: y)
}

#Preview("BouncyBriefcase") {
    @Previewable @State var isOpened = true
    VStack {
        BouncyBriefcase(isOpened: isOpened)
            .frame(width: 48, height: 48)

        Button("Toggle") {
            isOpened.toggle()
        }
    }
}
