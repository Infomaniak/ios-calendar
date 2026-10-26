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
import Contacts
import ESDSFoundation
import InfomaniakCoreUIResources
import InfomaniakOnboarding
import SwiftUI

extension Slide {
    static var onboardingSlides: [Slide] {
        return [
            Slide(
                backgroundImage: UIImage(),
                backgroundImageTintColor: nil,
                content: .illustration(CalendarResourcesAsset.Images.onboardingStart.image),
                bottomView: OnboardingTextView(text: .oneSlide)
            ),
            Slide(
                backgroundImage: UIImage(),
                backgroundImageTintColor: nil,
                content: .illustration(CalendarResourcesAsset.Images.onboardingNotifications.image),
                bottomView: OnboardingTextView(text: .twoSlide)
            ),
            Slide(
                backgroundImage: UIImage(),
                backgroundImageTintColor: nil,
                content: .illustration(CalendarResourcesAsset.Images.onboardingContact.image),
                bottomView: OnboardingTextView(text: .threeSlide)
            ),
            Slide(
                backgroundImage: UIImage(),
                backgroundImageTintColor: nil,
                content: .illustration(CalendarResourcesAsset.Images.onboardingEnd.image),
                bottomView: OnboardingTextView(text: .fourSlide)
            )
        ]
    }
}

enum OnboardingStep: CaseIterable {
    case login
    case notifications
    case contacts
    case everythingReady
}

public struct OnboardingView: View {
    @Environment(\.esdsTheme) private var theme
    @EnvironmentObject private var rootViewState: RootViewState

    @State private var selection = 0
    @State private var isTransitionInProgress = false

    @StateObject private var loginHandler = LoginHandler()

    private let steps = OnboardingStep.allCases

    public init() {}

    public var body: some View {
        WaveView(slides: Slide.onboardingSlides, selectedSlide: $selection) { index in
            let step = steps[index]
            if step == .login {
                OnboardingBottomButtonsView(loginHandler: loginHandler)
            } else {
                Button {
                    nextPressed(step: step)
                } label: {
                    Text(step == .everythingReady ? CalendarResourcesStrings.buttonStart : CoreUILocalizable.buttonNext)
                }
                .buttonStyle(.ikBorderedProminent)
                .ikButtonFullWidth(true)
                .controlSize(.large)
                .padding(.horizontal, value: .large)
            }
        }
        .ignoresSafeArea()
        .loginErrorAlert(loginHandler: loginHandler)
        .onChange(of: loginHandler.isLoggedIn) { _, isLoggedIn in
            guard isLoggedIn, steps[selection] == .login else { return }
            Task { await goToNextStep() }
        }
        .background(theme.color.backgroundElevationSunken)
    }

    private func nextPressed(step: OnboardingStep) {
        guard !isTransitionInProgress else { return }
        isTransitionInProgress = true
        Task {
            defer { isTransitionInProgress = false }
            switch step {
            case .notifications:
                await requestNotificationsIfNeeded()
            case .contacts:
                await requestContactsIfNeeded()
            case .everythingReady:
                rootViewState.completeOnboarding()
                return
            case .login:
                break
            }
            await goToNextStep()
        }
    }

    private func requestNotificationsIfNeeded() async {
        guard await isNotificationsPermissionNotDetermined() else { return }
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    private func requestContactsIfNeeded() async {
        guard isContactsPermissionNotDetermined() else { return }
        _ = try? await CNContactStore().requestAccess(for: .contacts)
    }

    private func isNotificationsPermissionNotDetermined() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .notDetermined
    }

    private func isContactsPermissionNotDetermined() -> Bool {
        CNContactStore.authorizationStatus(for: .contacts) == .notDetermined
    }

    private func shouldShow(step: OnboardingStep) async -> Bool {
        switch step {
        case .login:
            return false
        case .notifications:
            return await isNotificationsPermissionNotDetermined()
        case .contacts:
            return isContactsPermissionNotDetermined()
        case .everythingReady:
            return steps[selection] != .login
        }
    }

    private func goToNextStep() async {
        var nextIndex = selection + 1
        while nextIndex < steps.count, await !shouldShow(step: steps[nextIndex]) {
            nextIndex += 1
        }

        guard nextIndex < steps.count else {
            rootViewState.completeOnboarding()
            return
        }

        withAnimation {
            selection = nextIndex
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(RootViewState.previewOnboarding)
}
