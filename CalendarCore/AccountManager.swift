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

import DeviceAssociation
import Foundation
@preconcurrency import InfomaniakCore
import InfomaniakDI
import InfomaniakLogin
@preconcurrency import KmpCalendar
import OSLog

public final class NoOpRefreshTokenDelegate: RefreshTokenDelegate {
    public func didUpdateToken(newToken: ApiToken, oldToken: ApiToken) {}
    public func didFailRefreshToken(_ token: ApiToken) {}
}

public actor AccountManager {
    public typealias UserId = Int

    @LazyInjectService private var networkLoginService: InfomaniakNetworkLoginable
    @LazyInjectService private var tokenStore: TokenStore
    @LazyInjectService private var deviceManager: DeviceManagerable
    @LazyInjectService private var calendarSDK: CalendarCoreGraph
    @LazyInjectService private var davCredentialsKeychainHelper: DavCredentialsKeychainHelper

    public private(set) var calendarAccounts: [UserId: CalendarAccount] = [:]

    public let calendarAccountsStream: AsyncStream<[CalendarAccount]>
    private let calendarAccountsStreamContinuation: AsyncStream<[CalendarAccount]>.Continuation

    private let userProfileStore = UserProfileStore()

    public init() {
        (calendarAccountsStream, calendarAccountsStreamContinuation) = AsyncStream.makeStream(of: [CalendarAccount].self)
    }

    public func loadAccounts() async {
        let tokens = tokenStore.getAllTokens().values
        for token in tokens {
            do {
                let calendarAccount = try await calendarAccountFor(token: token.apiToken)
                calendarAccounts[calendarAccount.id] = calendarAccount
            } catch {
                Logger.general.error("Failed to load account for userId \(token.apiToken.userId): \(error)")
            }
        }
        calendarAccountsStreamContinuation.yield(Array(calendarAccounts.values))
    }

    public func createAndSetCurrentAccount(code: String, codeVerifier: String) async throws {
        let token = try await networkLoginService.apiTokenUsing(code: code, codeVerifier: codeVerifier)
        try await createAccount(token: token)
    }

    public func createAndSetCurrentAccount(token: ApiToken) async throws {
        try await createAccount(token: token)
    }

    public func removeAccountFor(userId: Int) async {
        calendarAccounts[userId] = nil
        tokenStore.removeTokenFor(userId: userId)
        try? await davCredentialsKeychainHelper.deleteCredentials(for: userId)
        await userProfileStore.removeUserProfile(id: userId)
        deviceManager.forgetLocalDeviceHash(forUserId: userId)

        calendarAccountsStreamContinuation.yield(Array(calendarAccounts.values))
    }

    private func calendarAccountFor(token: ApiToken) async throws -> CalendarAccount {
        let user = try await getOrCreateUserProfile(token: token)
        let davCredentials = try await getOrCreateDavCredentials(token: token)

        try await calendarSDK.accountManager.doInitAccount(accountId: Int64(token.userId), credentials: davCredentials)
        return CalendarAccount(token: token, user: user, davCredentials: davCredentials)
    }

    private func getOrCreateUserProfile(token: ApiToken) async throws -> UserProfile {
        if let userProfile = await userProfileStore.getUserProfile(id: token.userId) {
            return userProfile
        } else {
            let apiFetcher = getApiFetcher(token: token)
            return try await userProfileStore.updateUserProfile(with: apiFetcher, options: .all)
        }
    }

    private func getOrCreateDavCredentials(token: ApiToken) async throws -> DavCredentials {
        if let credentials = await davCredentialsKeychainHelper.retrieveCredentials(for: token.userId) {
            return credentials
        } else {
            let credentials = try await calendarSDK.accountManager.retrieveDavCredential(authToken: token.accessToken)
            try await davCredentialsKeychainHelper.storeCredentials(credentials, for: token.userId)
            return credentials
        }
    }

    private func getApiFetcher(token: ApiToken) -> ApiFetcher {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiFetcher = ApiFetcher(decoder: decoder)
        apiFetcher.createAuthenticatedSession(
            token,
            authenticator: OAuthAuthenticator(refreshTokenDelegate: NoOpRefreshTokenDelegate()),
            additionalAdapters: [UserAgentAdapter()]
        )

        return apiFetcher
    }

    private func createAccount(token: ApiToken) async throws {
        let calendarAccount = try await calendarAccountFor(token: token)
        calendarAccounts[calendarAccount.id] = calendarAccount

        let deviceId = try await deviceManager.getOrCreateCurrentDevice().uid
        tokenStore.addToken(newToken: token, associatedDeviceId: deviceId)

        calendarAccountsStreamContinuation.yield(Array(calendarAccounts.values))
    }
}
