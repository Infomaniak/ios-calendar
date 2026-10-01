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

private final class AIEventGenerationShaderBundle {}

@available(anyAppleOS 26.0, *)
struct AIEventGenerationBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var startDate = Date.now

    let isBackgroundVisible: Bool
    let isGlowVisible: Bool
    let isGenerating: Bool
    let isAppearing: Bool

    private static let shaders = ShaderLibrary.bundle(Bundle(for: AIEventGenerationShaderBundle.self))

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSince(startDate)
                let size = Shader.Argument.float2(geometry.size)
                let elapsed = Shader.Argument.float(Float(time))
                let isRippleEnabled = isAppearing && isBackgroundVisible && !reduceMotion && time < 0.95

                ZStack {
                    Rectangle()
                        .colorEffect(Self.shaders.euriaBackground(size, elapsed))
                        .opacity(isBackgroundVisible ? 0.05 : 0)
                        .visualEffect { content, proxy in
                            content.layerEffect(
                                Self.shaders.euriaRipple(
                                    .float2(CGPoint(x: proxy.size.width / 2, y: 0)),
                                    .float2(proxy.size),
                                    elapsed
                                ),
                                maxSampleOffset: CGSize(width: 28, height: 28),
                                isEnabled: isRippleEnabled
                            )
                        }

                    Rectangle()
                        .colorEffect(Self.shaders.euriaScreenGlow(size, elapsed))
                        .mask {
                            glowMask
                        }
                        .opacity(isGenerating ? 1 : 0.7)
                        .animation(.spring(duration: 0.3, bounce: 0), value: isGenerating)
                        .opacity(isGlowVisible ? 1 : 0)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var glowMask: some View {
        ZStack {
            ConcentricRectangle()
                .stroke(.white, lineWidth: 30)
                .blur(radius: 20)
                .opacity(0.35)

            ConcentricRectangle()
                .stroke(.white, lineWidth: 10)
                .blur(radius: 6)
                .opacity(0.65)

            ConcentricRectangle()
                .stroke(.white, lineWidth: 2)
        }
        .padding(2)
    }
}
