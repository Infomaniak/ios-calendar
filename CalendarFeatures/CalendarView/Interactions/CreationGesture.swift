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
#if canImport(UIKit)
import UIKit
#endif

enum CreationGesturePhase {
    case began
    case changed
    case ended
    case cancelled
}

extension View {
    /// Creates an event from an empty area of the calendar, reporting locations in the local coordinate space.
    ///
    /// Touch: long press, then move the finger to adjust. Pointer: double-click. macOS: click and drag to adjust.
    func creationGesture(action: @escaping (CreationGesturePhase, CGPoint) -> Void) -> some View {
        modifier(CreationGestureModifier(action: action))
    }
}

private struct CreationGestureModifier: ViewModifier {
    #if !canImport(UIKit)
    @State private var isDragging = false
    #endif

    let action: (CreationGesturePhase, CGPoint) -> Void

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content
            .gesture(LongPressCreationGesture(action: action))
            .gesture(PointerDoubleClickGesture { location in
                action(.began, location)
                action(.ended, location)
            })
        #else
        content
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .local)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            action(.began, value.startLocation)
                        }
                        action(.changed, value.location)
                    }
                    .onEnded { value in
                        isDragging = false
                        action(.ended, value.location)
                    }
            )
            .gesture(
                SpatialTapGesture(count: 2, coordinateSpace: .local)
                    .onEnded { value in
                        action(.began, value.location)
                        action(.ended, value.location)
                    }
            )
        #endif
    }
}

#if canImport(UIKit)
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
        let location = context.converter.location(in: .local)
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
        action(context.converter.location(in: .local))
    }
}
#endif
