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

import AuthenticationServices
import CalendarCore
import Foundation
@preconcurrency import InfomaniakCore
import InfomaniakDeviceCheck
import InfomaniakDI
import InfomaniakLogin
import InterAppLogin

@MainActor
public final class LoginHandler: InfomaniakLoginDelegate, ObservableObject {
    @LazyInjectService private var loginService: InfomaniakLoginable
    @LazyInjectService private var tokenService: InfomaniakNetworkLoginable
    @LazyInjectService private var accountManager: AccountManager

    @Published public var isLoading = false
    @Published public var error: LoginError?

    public init() {}

    public nonisolated func didCompleteLoginWith(code: String, verifier: String) {
        Task {
            await loginSuccessful(code: code, codeVerifier: verifier)
        }
    }

    public nonisolated func didFailLoginWith(error: any Error) {
        Task {
            await loginFailed(error: error)
        }
    }

    public func login(dimissHandler: (() -> Void)? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await loginService.asWebAuthenticationLoginFrom(
                anchor: ASPresentationAnchor(),
                useEphemeralSession: true,
                hideCreateAccountButton: false
            )
            try await accountManager.createAndSetCurrentAccount(code: result.code, codeVerifier: result.verifier)

            dimissHandler?()
        } catch {
            loginFailed(error: error)
        }
    }

    public func loginWith(accounts: [ConnectedAccount], dimissHandler: (() -> Void)? = nil) async {
        isLoading = true
        defer { isLoading = false }

        let loginResults: [Bool] = await withTaskGroup { group in
            for account in accounts {
                group.addTask {
                    do {
                        let derivatedToken = try await self.tokenService.derivateApiToken(for: account)
                        try await self.accountManager.createAndSetCurrentAccount(token: derivatedToken)
                        return true
                    } catch {
                        return false
                    }
                }
            }

            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        if !loginResults.contains(true) {
            error = .loginFailed(error: NSError(
                domain: "LoginHandler",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "!Failed to login with all accounts"]
            ))
        } else {
            dimissHandler?()
        }
    }

    public func loginAfterAccountCreation(from viewController: UIViewController) {
        isLoading = true
        loginService.setupWebviewNavbar(
            title: "\(CalendarTargetAssembly.loginConfig.loginURL.host(percentEncoded: false) ?? "Infomaniak")",
            titleColor: nil,
            color: nil,
            buttonColor: nil,
            clearCookie: false,
            timeOutMessage: nil
        )
        loginService.webviewLoginFrom(
            viewController: viewController,
            hideCreateAccountButton: true,
            delegate: self
        )
    }

    private func loginFailed(error: Error) {
        guard (error as? ASWebAuthenticationSessionError)?.code != .canceledLogin else { return }
        self.error = .loginFailed(error: error)
    }

    private func loginSuccessful(code: String, codeVerifier: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await accountManager.createAndSetCurrentAccount(code: code, codeVerifier: codeVerifier)
        } catch {
            loginFailed(error: error)
        }
    }
}

public enum LoginError: Error, LocalizedError, Equatable {
    case loginFailed(error: Error)

    public var errorDescription: String? {
        switch self {
        case .loginFailed(let error):
            return error.localizedDescription
        }
    }

    public static func == (lhs: LoginError, rhs: LoginError) -> Bool {
        switch (lhs, rhs) {
        case (.loginFailed, .loginFailed):
            return true
        }
    }
}

public extension InfomaniakNetworkLoginable {
    private var deviceCheckEnvironment: InfomaniakDeviceCheck.Environment {
        switch ApiEnvironment.current {
        case .prod:
            return .prod
        case .preprod:
            return .preprod
        case .customHost(let host):
            return .init(url: URL(string: "https://\(host)/1/attest")!)
        }
    }

    func derivateApiToken(for account: ConnectedAccount) async throws -> ApiToken {
        try await derivateApiToken(account.token)
    }

    func derivateApiToken(_ token: ApiToken) async throws -> ApiToken {
        let attestationToken = try await InfomaniakDeviceCheck(environment: deviceCheckEnvironment)
            .generateAttestationFor(
                targetUrl: CalendarTargetAssembly.loginConfig.loginURL.appendingPathComponent("token"),
                bundleId: CalendarTargetAssembly.bundleId,
                bypassValidation: deviceCheckEnvironment == .preprod
            )

        return try await derivateApiToken(
            using: token,
            attestationToken: attestationToken
        )
    }
}
