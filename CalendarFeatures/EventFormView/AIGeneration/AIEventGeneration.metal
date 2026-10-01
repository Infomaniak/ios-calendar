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

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Cobalt, luminous blue and icy cyan inspired by the Euria identity.
static float noiseHash(float2 point) {
    return fract(sin(dot(point, float2(127.1, 311.7))) * 43758.5453);
}

static float smoothNoise(float2 point) {
    float2 cell = floor(point);
    float2 fraction = fract(point);
    float2 blend = fraction * fraction * (3.0 - 2.0 * fraction);
    return mix(
        mix(noiseHash(cell), noiseHash(cell + float2(1.0, 0.0)), blend.x),
        mix(noiseHash(cell + float2(0.0, 1.0)), noiseHash(cell + 1.0), blend.x),
        blend.y
    );
}

static float flowingNoise(float2 point) {
    return smoothNoise(point) * 0.57
        + smoothNoise(point * 2.03 + 7.1) * 0.29
        + smoothNoise(point * 4.01 + 13.7) * 0.14;
}

[[ stitchable ]] half4 euriaBackground(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / max(size, float2(1.0));
    float2 point = (position - size * 0.5) / max(min(size.x, size.y), 1.0);
    float drift = time * 0.13;
    float2 warp = float2(
        flowingNoise(point * 1.8 + float2(drift, -drift * 0.6)),
        flowingNoise(point * 1.8 + float2(-drift * 0.5, drift) + 4.3)
    );
    float cloud = flowingNoise(point * 2.2 + warp * 2.0 + float2(drift * 0.3, -drift * 0.4));
    float ribbon = exp(-pow((cloud - 0.53) * 9.0, 2.0));
    float edge = smoothstep(0.1, 0.65, length((uv - 0.5) * float2(1.0, 0.8)));

    float3 midnight = float3(0.012, 0.025, 0.095);
    float3 cobalt = float3(0.055, 0.13, 0.63);
    float3 blue = float3(0.06, 0.43, 0.98);
    float3 cyan = float3(0.25, 0.84, 1.0);
    float3 light = mix(cobalt, blue, smoothstep(0.3, 0.7, cloud));
    float3 rgb = mix(midnight, light, (0.2 + edge * 0.6) * ribbon);
    rgb += cyan * pow(ribbon, 6.0) * (0.025 + edge * 0.1);

    // Premultiplied alpha lets the form gently show through the dark centre.
    float alpha = 0.94;
    return half4(half3(rgb * alpha), half(alpha)) * color.a;
}

[[ stitchable ]] half4 euriaScreenGlow(float2 position, half4 color, float2 size, float time) {
    float2 point = position - size * 0.5;
    // SwiftUI masks this light with the device's actual concentric corner geometry.
    float angle = atan2(point.y, point.x);
    float flow = 0.5 + 0.5 * sin(angle * 2.0 - time * 0.65 + sin(angle * 3.0 + time * 0.25));
    float pulse = 0.86 + 0.14 * sin(time * 1.6 + angle * 2.0);
    float3 blue = float3(0.09, 0.28, 1.0);
    float3 cyan = float3(0.22, 0.84, 1.0);
    float3 tint = mix(blue, cyan, flow);
    tint = mix(tint, float3(0.72, 0.95, 1.0), pow(flow, 4.0) * 0.4);
    return half4(half3(tint * pulse), half(pulse)) * color.a;
}

[[ stitchable ]] half4 euriaRipple(float2 position, SwiftUI::Layer layer, float2 origin, float2 size, float time) {
    float2 delta = position - origin;
    float distance = length(delta);
    float2 direction = delta / max(distance, 0.001);
    float farthestCorner = max(length(max(abs(origin), abs(size - origin))), 1.0);
    float front = distance - farthestCorner * time / 0.7;
    float envelope = exp(-pow(front / 90.0, 2.0));
    float lifetime = smoothstep(0.0, 0.05, time) * (1.0 - smoothstep(0.55, 0.95, time));

    // A single travelling wave, bounded by the 28-point sample offset in SwiftUI.
    float displacement = sin(front / 16.0) * envelope * lifetime * 28.0;
    half4 sampled = layer.sample(position + direction * displacement);

    // A broad cyan crest makes the wave read clearly over the translucent backdrop.
    float highlight = exp(-pow(front / 24.0, 2.0)) * lifetime * 0.28;
    half4 crest = half4(half3(float3(0.22, 0.84, 1.0) * highlight), half(highlight));
    return sampled * half(1.0 - highlight) + crest;
}
