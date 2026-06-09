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
import InfomaniakDeviceCheck
import InfomaniakDI
import InfomaniakLogin
import InterAppLogin
import OSLog

open class CalendarTargetAssembly: TargetAssembly {
    private static let apiEnvironment: ApiEnvironment = .prod
    private static let dbRootPath = "calendar"
    private static let appGroupIdentifier = "group.\(bundleId)"
    private static let sharedAppGroupName = "group.com.infomaniak"
    private static let appIdentifierPrefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as! String
    private static let keychainGroupIdentifier = "\(appIdentifierPrefix)\(bundleId)"

    public static let bundleId = "com.infomaniak.calendar"
    public static let loginConfig = InfomaniakLogin.Config(
        clientId: "CE011334-F75A-4263-9F9F-45FC5A142F59",
        loginURL: URL(string: "https://login.\(apiEnvironment.host)/")!,
        redirectURI: "com.infomaniak.sync://oauth2redirect",
        accessType: nil
    )

    override public init() {
        super.init()
        ApiEnvironment.current = Self.apiEnvironment
    }

    override open class func getCommonServices() -> [Factory] {
        return [
            Factory(type: AccountManager.self) { _, _ in
                AccountManager()
            },
            Factory(type: InfomaniakNetworkLoginable.self) { _, _ in
                InfomaniakNetworkLogin(config: loginConfig)
            },
            Factory(type: InfomaniakLoginable.self) { _, _ in
                InfomaniakLogin(config: loginConfig)
            },
            Factory(type: KeychainHelper.self) { _, _ in
                KeychainHelper(accessGroup: Self.keychainGroupIdentifier)
            },
            Factory(type: TokenStore.self) { _, _ in
                TokenStore()
            },
            Factory(type: DeviceManagerable.self) { _, _ in
                let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
                return DeviceManager(
                    appGroupIdentifier: Self.sharedAppGroupName,
                    appMarketingVersion: version,
                    capabilities: []
                )
            },
            Factory(type: AppGroupPathProvidable.self) { _, _ in
                guard let provider = AppGroupPathProvider(
                    realmRootPath: dbRootPath,
                    appGroupIdentifier: appGroupIdentifier
                ) else {
                    fatalError("could not safely init AppGroupPathProvider")
                }

                return provider
            },
            Factory(type: ConnectedAccountManagerable.self) { _, _ in
                ConnectedAccountManager(currentAppKeychainIdentifier: Self.bundleId)
            }
        ]
    }

    override open class func getTargetServices() -> [Factory] {
        return [
            Factory(type: AppLaunchCounter.self) { _, _ in
                AppLaunchCounter()
            }
        ]
    }
}
