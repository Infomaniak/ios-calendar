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

import CalendarResources
import InfomaniakOnboarding
import Lottie
import SwiftUI

struct WaveView<BottomView: View>: UIViewControllerRepresentable {
    @Binding var selectedSlide: Int

    let slides: [Slide]

    let dismissHandler: (@Sendable () -> Void)?

    @ViewBuilder var bottomView: (Int) -> BottomView

    init(
        slides: [Slide],
        selectedSlide: Binding<Int>,
        dismissHandler: (@Sendable () -> Void)? = nil,
        @ViewBuilder bottomView: @escaping (Int) -> BottomView
    ) {
        self.slides = slides
        _selectedSlide = selectedSlide
        self.dismissHandler = dismissHandler
        self.bottomView = bottomView
    }

    func makeUIViewController(context: Context) -> OnboardingViewController {
        let configuration = OnboardingConfiguration(
            headerImage: nil,
            slides: slides,
            pageIndicatorColor: UIColor.tintColor,
            isScrollEnabled: true,
            dismissHandler: dismissHandler,
            isPageIndicatorHidden: false
        )

        let controller = OnboardingViewController(configuration: configuration)
        controller.delegate = context.coordinator

        return controller
    }

    func updateUIViewController(_ uiViewController: OnboardingViewController, context: Context) {
        if uiViewController.pageIndicator.currentPage != selectedSlide {
            uiViewController.setSelectedSlide(index: selectedSlide)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: OnboardingViewControllerDelegate {
        let parent: WaveView<BottomView>

        init(parent: WaveView<BottomView>) {
            self.parent = parent
        }

        func bottomViewForIndex(_ index: Int) -> (any View)? {
            return parent.bottomView(index)
        }

        func shouldAnimateBottomViewForIndex(_ index: Int) -> Bool {
            return index == parent.slides.count - 1
        }

        func willDisplaySlideViewCell(_ slideViewCell: SlideCollectionViewCell, at index: Int) {}

        func currentIndexChanged(newIndex: Int) {
            Task { @MainActor in
                parent.$selectedSlide.wrappedValue = newIndex
            }
        }
    }
}
