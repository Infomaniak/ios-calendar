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

import CalendarCore
import CalendarCoreUI
import CalendarResources
import OSLog
import SwiftUI

@available(anyAppleOS 26.0, *)
struct AIEventGenerationView: View {
    @State private var prompt = ""
    @State private var didSubmitPrompt = false

    @State private var generationError: CalendarError?

    let draft: EventDraft
    let onGenerated: (EventDraft) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.1)
                .ignoresSafeArea()

            TextField("What's going on?", text: $prompt)
                .textFieldStyle(AIPromptTextFieldStyle())
                .disabled(didSubmitPrompt)
                .onSubmit {
                    guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    didSubmitPrompt = true
                }
                .padding(24)
        }
        .task(id: didSubmitPrompt) {
            guard didSubmitPrompt else { return }
            await generateDraft()
        }
        .alert(error: $generationError) {}
    }

    private func generateDraft() async {
        defer { didSubmitPrompt = false }

        do {
            let result = try await AIEventGenerator().generateDraftFrom(userRequest: prompt, basedOn: draft)
            try Task.checkCancellation()
            onGenerated(result)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            Logger.view.error("Failed to generate event draft: \(error.localizedDescription)")
            generationError = .unknown
        }
    }
}

private struct AIPromptTextFieldStyle: TextFieldStyle {
    @Environment(\.isEnabled) private var isEnabled

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundStyle(isEnabled ? Color.white : Color.white.opacity(0.65))
            .tint(.white)
            .environment(\.colorScheme, .dark)
            .padding(24)
            .background(.black, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

@available(anyAppleOS 26.0, *)
#Preview {
    AIEventGenerationView(draft: .empty()) { _ in }
}
