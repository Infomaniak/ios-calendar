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

import Foundation
import KmpCalendar
import OSLog

public actor DavCredentialsKeychainHelper {
    private let logger = Logger(category: "DavCredentialsKeychainHelper")

    enum ErrorDomain: Error {
        case encodingError
        case decodingError
        case keychainError(status: OSStatus)
    }

    let accessGroup: String
    let tag = Data("com.infomaniak.dav-credentials".utf8)

    public init(accessGroup: String) {
        self.accessGroup = accessGroup
    }

    private func userIdData(value: Int) throws -> Data {
        return withUnsafeBytes(of: value) { Data($0) }
    }

    private func userIdFromData(_ data: Data) throws -> Int {
        guard data.count == MemoryLayout<Int>.size else {
            throw ErrorDomain.decodingError
        }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }

    public func storeCredentials(_ credentials: DavCredentials, for userId: Int) throws {
        if retrieveCredentials(for: userId) != nil {
            try updateCredentials(credentials, userIdData: userIdData(value: userId), for: userId)
        } else {
            try addCredentials(credentials, userIdData: userIdData(value: userId), for: userId)
        }
    }

    private func addCredentials(_ credentials: DavCredentials, userIdData: Data, for userId: Int) throws {
        guard let passwordData = credentials.password.data(using: .utf8) else {
            logger.error("Failed to encode password for userId \(userId)")
            throw ErrorDomain.encodingError
        }

        let queryAdd: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrService as String: tag,
            kSecAttrAccount as String: credentials.username,
            kSecAttrGeneric as String: userIdData,
            kSecValueData as String: passwordData
        ]

        let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
        guard resultCode == noErr else {
            logger.error("Failed to add DAV credentials for userId \(userId): \(resultCode)")
            throw ErrorDomain.keychainError(status: resultCode)
        }

        logger.info("Successfully saved DAV credentials for userId \(userId)")
    }

    private func updateCredentials(_ credentials: DavCredentials, userIdData: Data, for userId: Int) throws {
        guard let passwordData = credentials.password.data(using: .utf8) else {
            logger.error("Failed to encode password for userId \(userId)")
            throw ErrorDomain.encodingError
        }

        let queryUpdate: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: credentials.username,
            kSecAttrService as String: tag,
            kSecAttrAccessGroup as String: accessGroup
        ]

        let attributes: [String: Any] = [
            kSecAttrGeneric as String: userIdData,
            kSecValueData as String: passwordData
        ]

        let resultCode = SecItemUpdate(queryUpdate as CFDictionary, attributes as CFDictionary)
        guard resultCode == noErr else {
            logger.error("Failed to update DAV credentials for userId \(userId): \(resultCode)")
            throw ErrorDomain.keychainError(status: resultCode)
        }

        logger.info("Successfully updated DAV credentials for userId \(userId) ? \(resultCode == noErr)")
    }

    public func retrieveCredentials(for userId: Int) -> DavCredentials? {
        let queryFindOne: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecReturnAttributes as String: kCFBooleanTrue as Any,
            kSecReturnRef as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?

        let resultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(queryFindOne as CFDictionary, UnsafeMutablePointer($0))
        }

        guard resultCode == noErr, let array = result as? [[String: Any]] else {
            return nil
        }

        var credentials: DavCredentials?

        for item in array {
            if let userIdData = item[kSecAttrGeneric as String] as? Data,
               let storedUserId = try? userIdFromData(userIdData),
               storedUserId == userId,
               let passwordData = item[kSecValueData as String] as? Data,
               let password = String(data: passwordData, encoding: .utf8),
               let username = item[kSecAttrAccount as String] as? String {
                credentials = DavCredentials(username: username, password: password)
                break
            }
        }

        return credentials
    }

    public func deleteCredentials(for userId: Int) throws {
        let userIdData = try userIdData(value: userId)

        let queryDelete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrGeneric as String: userIdData
        ]

        let resultCode = SecItemDelete(queryDelete as CFDictionary)
        guard resultCode == noErr else {
            logger.error("Failed to delete DAV credentials for userId \(userId): \(resultCode)")
            throw ErrorDomain.keychainError(status: resultCode)
        }
        logger.info("Successfully deleted DAV credentials for userId \(userId)")
    }

    public func deleteAllCredentials() throws {
        let queryDelete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecAttrAccessGroup as String: accessGroup
        ]

        let resultCode = SecItemDelete(queryDelete as CFDictionary)
        guard resultCode == noErr else {
            logger.error("Failed to delete all DAV credentials: \(resultCode)")
            throw ErrorDomain.keychainError(status: resultCode)
        }

        logger.info("Successfully deleted all DAV credentials")
    }
}
