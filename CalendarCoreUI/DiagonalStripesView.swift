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

public struct DiagonalStripesView: View {
    private let color: Color
    private let stripeColor: Color
    private let stripeWidth: CGFloat
    private let spacing: CGFloat

    public init(
        color: Color,
        stripeColor: Color = .clear,
        stripeWidth: CGFloat = 8,
        spacing: CGFloat = 24
    ) {
        self.color = color
        self.stripeColor = stripeColor
        self.stripeWidth = stripeWidth
        self.spacing = spacing
    }

    public var body: some View {
        Canvas { context, size in
            let stripes = stripesPath(in: size)
            let rect = Path(CGRect(origin: .zero, size: size))

            context.fill(stripes, with: .color(stripeColor))

            context.clip(to: stripes, options: .inverse)
            context.fill(rect, with: .color(color))
        }
    }

    private func stripesPath(in size: CGSize) -> Path {
        var lines = Path()
        let step = stripeWidth + spacing
        var offset = -size.height
        while offset < size.width {
            lines.move(to: CGPoint(x: offset, y: 0))
            lines.addLine(to: CGPoint(x: offset + size.height, y: size.height))
            offset += step
        }
        return lines.strokedPath(StrokeStyle(lineWidth: stripeWidth))
    }
}

#Preview {
    DiagonalStripesView(color: .red, stripeColor: .red.opacity(0.5))
        .frame(width: 180, height: 180)
}
