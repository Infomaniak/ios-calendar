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

final class NextEventCardViewModel: ObservableObject {
    @Published var scrollProgress = 1.0
}

struct NextEventCardView: View {
    @ObservedObject var model: NextEventCardViewModel

    let event = UIEvent.preview

    var body: some View {
        NextEventContentCardView(event: event, progress: model.scrollProgress)
    }
}

struct NextEventContentCardView: View {
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
                .opacity(progress)
                .blur(radius: lerp(a: 2, b: 0))
                .opacity(lerp(a: 0, b: 1))
                .frame(height: lerp(a: 0, b: 12))
                .padding(.bottom, lerp(a: 0, b: 12))
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: lerp(a: 13, b: 16), weight: .bold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Material.regular, in: .rect(cornerRadius: 16))
    }

    private func lerp(a: Double, b: Double) -> Double {
        return a * (1 - progress) + b * progress
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
            .padding(.vertical)

        Spacer()

        Slider(value: $progress, in: 0...1)
            .padding()
    }
    .padding()
}
