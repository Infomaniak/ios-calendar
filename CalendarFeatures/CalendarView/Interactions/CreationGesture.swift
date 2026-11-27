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
import UIKit

enum CreationGesturePhase {
    case began
    case changed
    case ended
    case cancelled
}

extension View {
    /// Creates an event from an empty area of the calendar, reporting locations in `CreationPage.coordinateSpace`.
    ///
    /// Touch: long press, then move the finger to adjust. Pointer: double-click.
    func creationGesture(action: @escaping (CreationGesturePhase, CGPoint) -> Void) -> some View {
        gesture(LongPressCreationGesture(action: action))
            .gesture(PointerDoubleClickGesture { location in
                action(.began, location)
                action(.ended, location)
            })
    }
}

/// A UIKit long press keeps the scroll views arbitration: moving before the delay scrolls instead of creating.
private struct LongPressCreationGesture: UIGestureRecognizerRepresentable {
    static let minimumPressDuration: TimeInterval = 0.4
    static let allowableMovement: CGFloat = 10

    let action: (CreationGesturePhase, CGPoint) -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = Self.minimumPressDuration
        recognizer.allowableMovement = Self.allowableMovement
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        let location = context.converter.location(in: CreationPage.coordinateSpace)
        switch recognizer.state {
        case .began:
            action(.began, location)
        case .changed:
            action(.changed, location)
        case .ended:
            action(.ended, location)
        case .cancelled, .failed:
            action(.cancelled, location)
        default:
            break
        }
    }
}

/// Double-click with a pointer (trackpad, mouse, Mac Catalyst) creates an event, touches are left to the long press.
private struct PointerDoubleClickGesture: UIGestureRecognizerRepresentable {
    let action: (CGPoint) -> Void

    func makeUIGestureRecognizer(context: Context) -> UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer()
        recognizer.numberOfTapsRequired = 2
        recognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UITapGestureRecognizer, context: Context) {
        guard recognizer.state == .ended else { return }
        action(context.converter.location(in: CreationPage.coordinateSpace))
    }
}
