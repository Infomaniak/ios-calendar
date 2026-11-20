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
        path.move(to: CGPoint(x: 8, y: 6))
        path.addLine(to: CGPoint(x: 8, y: 4))
        path.addCurve(to: CGPoint(x: 10, y: 2), control1: CGPoint(x: 8, y: 2.895), control2: CGPoint(x: 8.895, y: 2))
        path.addLine(to: CGPoint(x: 14, y: 2))
        path.addCurve(to: CGPoint(x: 16, y: 4), control1: CGPoint(x: 15.105, y: 2), control2: CGPoint(x: 16, y: 2.895))
        path.addLine(to: CGPoint(x: 16, y: 6))

        let leftTop = Self.y(atX: 2, onCubic: p[11], p[12], p[13], p[14])
        let rightTop = Self.y(atX: 22, onCubic: p[8], p[9], p[10], p[11])
        path.move(to: CGPoint(x: 2, y: leftTop))
        path.addLine(to: CGPoint(x: 2, y: 18))
        path.addCurve(to: CGPoint(x: 4, y: 20), control1: CGPoint(x: 2, y: 19.105), control2: CGPoint(x: 2.895, y: 20))
        path.addLine(to: CGPoint(x: 20, y: 20))
        path.addCurve(to: CGPoint(x: 22, y: 18), control1: CGPoint(x: 21.105, y: 20), control2: CGPoint(x: 22, y: 19.105))
        path.addLine(to: CGPoint(x: 22, y: rightTop))

        // Flap
        path.move(to: p[0])
        path.addLine(to: p[1])
        path.addCurve(to: p[4], control1: p[2], control2: p[3])
        path.addLine(to: p[5])
        path.addCurve(to: p[8], control1: p[6], control2: p[7])
        path.addCurve(to: p[11], control1: p[9], control2: p[10])
        path.addCurve(to: p[14], control1: p[12], control2: p[13])
        path.addCurve(to: p[17], control1: p[15], control2: p[16])
        path.addLine(to: p[18])
        path.addCurve(to: p[21], control1: p[19], control2: p[20])
        path.closeSubpath()

        // Clasp
        let claspY = 12 + (9.5 - 12) * t
        path.move(to: CGPoint(x: 12, y: claspY))
        path.addLine(to: CGPoint(x: 12.01, y: claspY))

        return path
    }

    private static let closedFlap: [CGPoint] = [
        CGPoint(x: 4, y: 6), CGPoint(x: 20, y: 6),
        CGPoint(x: 21.105, y: 6), CGPoint(x: 22, y: 6.895), CGPoint(x: 22, y: 8),
        CGPoint(x: 22, y: 13),
        CGPoint(x: 22, y: 13), CGPoint(x: 22, y: 13), CGPoint(x: 22, y: 13),
        CGPoint(x: 19.033, y: 14.959), CGPoint(x: 15.556, y: 16.003), CGPoint(x: 12, y: 16.003),
        CGPoint(x: 8.444, y: 16.003), CGPoint(x: 4.967, y: 14.959), CGPoint(x: 2, y: 13),
        CGPoint(x: 2, y: 13), CGPoint(x: 2, y: 13), CGPoint(x: 2, y: 13),
        CGPoint(x: 2, y: 8),
        CGPoint(x: 2, y: 6.895), CGPoint(x: 2.895, y: 6), CGPoint(x: 4, y: 6)
    ]

    private static let openFlap: [CGPoint] = [
        CGPoint(x: 4.5, y: 6), CGPoint(x: 19.5, y: 6),
        CGPoint(x: 20.35, y: 6), CGPoint(x: 21.05, y: 6.42), CGPoint(x: 21.48, y: 7.2),
        CGPoint(x: 22.7, y: 9.43),
        CGPoint(x: 23.02, y: 10.01), CGPoint(x: 22.95, y: 10.45), CGPoint(x: 22.4, y: 10.7),
        CGPoint(x: 18.9333, y: 12.2667), CGPoint(x: 15.4667, y: 13.05), CGPoint(x: 12, y: 13.05),
        CGPoint(x: 8.5333, y: 13.05), CGPoint(x: 5.0667, y: 12.2667), CGPoint(x: 1.6, y: 10.7),
        CGPoint(x: 1.05, y: 10.45), CGPoint(x: 0.98, y: 10.01), CGPoint(x: 1.3, y: 9.43),
        CGPoint(x: 2.52, y: 7.2),
        CGPoint(x: 2.95, y: 6.42), CGPoint(x: 3.65, y: 6), CGPoint(x: 4.5, y: 6)
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
