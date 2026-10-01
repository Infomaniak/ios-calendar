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
import OSLog
import SwiftUI

@available(anyAppleOS 26.0, *)
struct AIEventGenerationView: View {
    private enum Phase {
        case appearing
        case ready
        case generating
        case dismissing
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var prompt = ""

    @State private var generatedDraft: EventDraft?
    @State private var generationError: CalendarError?

    @State private var phase = Phase.appearing
    @State private var isBackgroundVisible = false
    @State private var isGlowVisible = false
    @State private var isPromptVisible = false
    @State private var isShowingThinking = false

    @FocusState private var isPromptFocused: Bool

    let draft: EventDraft
    let onGenerated: (EventDraft) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            AIEventGenerationBackground(
                isBackgroundVisible: isBackgroundVisible,
                isGlowVisible: isGlowVisible,
                isGenerating: phase == .generating,
                isAppearing: phase == .appearing
            )
            .contentShape(.rect)
            .onTapGesture(perform: cancel)
            .accessibilityLabel("Cancel event generation")
            .ignoresSafeArea()

            TextField("What's going on?", text: $prompt, axis: .vertical)
                .textFieldStyle(AIPromptTextFieldStyle(isThinking: isShowingThinking))
                .focused($isPromptFocused)
                .submitLabel(.go)
                .disabled(phase != .ready)
                .onSubmit {
                    guard phase == .ready, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        return
                    }

                    isPromptFocused = false
                    isShowingThinking = true
                    phase = .generating
                }
                .padding(24)
                .offset(y: isPromptVisible || reduceMotion ? 0 : 160)
                .opacity(isPromptVisible ? 1 : 0)
                .allowsHitTesting(isPromptVisible)
                .accessibilityHidden(!isPromptVisible)
        }
        .task(id: phase) {
            await runPhase()
        }
        .accessibilityAction(.escape, cancel)
        .alert(error: $generationError) {}
    }

    private func runPhase() async {
        switch phase {
        case .appearing:
            try? await animateAppearance()
        case .ready:
            isPromptFocused = true
        case .generating:
            await generateDraft()
        case .dismissing:
            try? await animateDismissal()
        }
    }

    private func animateAppearance() async throws {
        let fadeDuration = reduceMotion ? 0.1 : 0.2
        withAnimation(.spring(duration: fadeDuration, bounce: 0)) {
            isBackgroundVisible = true
        }
        try await Task.sleep(for: .seconds(fadeDuration))

        withAnimation(.spring(duration: fadeDuration, bounce: 0)) {
            isGlowVisible = true
        }
        try await Task.sleep(for: .seconds(fadeDuration))

        let promptDuration = reduceMotion ? 0.1 : 0.3
        withAnimation(.snappy(duration: promptDuration, extraBounce: 0.4)) {
            isPromptVisible = true
        }
        try await Task.sleep(for: .seconds(promptDuration + 0.5))

        phase = .ready
    }

    private func animateDismissal() async throws {
        isPromptFocused = false
        let promptDuration = reduceMotion ? 0.12 : 0.22
        withAnimation(.spring(duration: promptDuration, bounce: 0)) {
            isPromptVisible = false
        }
        try await Task.sleep(for: .seconds(promptDuration))

        let fadeDuration = reduceMotion ? 0.12 : 0.3
        withAnimation(.spring(duration: fadeDuration, bounce: 0)) {
            isGlowVisible = false
            isBackgroundVisible = false
        }
        try await Task.sleep(for: .seconds(fadeDuration))
        try Task.checkCancellation()

        if let generatedDraft {
            onGenerated(generatedDraft)
        } else {
            onDismiss()
        }
    }

    private func cancel() {
        guard phase != .dismissing else { return }
        generatedDraft = nil
        phase = .dismissing
    }

    private func generateDraft() async {
        do {
            let result = try await AIEventGenerator().generateDraftFrom(userRequest: prompt, basedOn: draft)
            try Task.checkCancellation()
            guard phase == .generating else { return }
            generatedDraft = result
            phase = .dismissing
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, phase == .generating else { return }
            Logger.view.error("Failed to generate event draft: \(error.localizedDescription)")
            generationError = .unknown
            isShowingThinking = false
            phase = .ready
        }
    }
}

private struct AIPromptTextFieldStyle: TextFieldStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isThinking: Bool

    func _body(configuration: TextField<Self._Label>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            configuration
                .font(.body)
                .foregroundStyle(isEnabled ? Color.white : Color.white.opacity(0.65))
                .tint(.white)
                .environment(\.colorScheme, .dark)

            if isThinking {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color(red: 0.22, green: 0.84, blue: 1))
                        .accessibilityHidden(true)

                    Text("Thinking…")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(AnyTransition.opacity.combined(with: .offset(y: reduceMotion ? 0 : 6)))
            }
        }
        .padding(24)
        .background(.black, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(red: 0.22, green: 0.84, blue: 1).opacity(0.35),
                                 Color(red: 0.09, green: 0.28, blue: 1).opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .animation(.spring(duration: reduceMotion ? 0.12 : 0.3, bounce: 0), value: isThinking)
        .phaseAnimator(isThinking && !reduceMotion ? [false, true] : [false]) { content, isBright in
            content.shadow(
                color: Color(red: 0.06, green: 0.43, blue: 0.98).opacity(isBright ? 0.4 : 0.22),
                radius: isBright ? 20 : 14
            )
        } animation: { _ in
            .spring(duration: 1.4, bounce: 0)
        }
    }
}

@available(anyAppleOS 26.0, *)
#Preview {
    AIEventGenerationView(draft: .empty(), onGenerated: { _ in }, onDismiss: {})
}
