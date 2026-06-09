/*
 Infomaniak Calendar - iOS App
 Copyright (C) 2026 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import CalendarCore
import Combine
import Foundation
import InfomaniakDI
import SwiftUI

public enum RootViewType: Equatable {
    case mainView
    case onboarding
    case preloading
}

@MainActor
public final class RootViewState: ObservableObject {
    @Published public var state: RootViewType = .preloading

    public init() {
        Task {
            @InjectService var accountManager: AccountManager
            for await calendarAccounts in await accountManager.calendarAccountsStream {
                transitionToMainViewIfPossible(calendarAccounts: calendarAccounts)
            }
        }
    }

    fileprivate init(state: RootViewType) {
        self.state = state
    }

    public func transitionToRootViewState(_ newState: RootViewType) {
        withAnimation {
            state = newState
        }
    }

    public func transitionToMainViewIfPossible(calendarAccounts: [CalendarAccount]) {
        if !calendarAccounts.isEmpty {
            state = .mainView
        } else {
            state = .onboarding
        }
    }
}

public extension RootViewState {
    static let previewMainView = RootViewState(state: .mainView)
    static let previewPreloading = RootViewState(state: .preloading)
    static let previewOnboarding = RootViewState(state: .onboarding)
}
