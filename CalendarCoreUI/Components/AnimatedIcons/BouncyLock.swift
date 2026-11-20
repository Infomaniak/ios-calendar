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

public struct BouncyLock: View {
    let isUnlocked: Bool
    let lineWidth: CGFloat

    public init(isUnlocked: Bool, lineWidth: CGFloat = 1.6) {
        self.isUnlocked = isUnlocked
        self.lineWidth = lineWidth
    }

    public var body: some View {
        BouncyIcon(shape: LockShape.self, isToggled: isUnlocked, lineWidth: lineWidth)
    }
}

private struct LockShape: AnimatedIconShape {
    var progress: CGFloat

    func iconPath() -> Path {
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

        return path
    }

    private func point(locked: (CGFloat, CGFloat), unlocked: (CGFloat, CGFloat), t: CGFloat) -> CGPoint {
        CGPoint(x: locked.0, y: locked.1).interpolated(to: CGPoint(x: unlocked.0, y: unlocked.1), progress: t)
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
