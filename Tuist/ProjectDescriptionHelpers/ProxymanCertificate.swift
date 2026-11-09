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
import ProjectDescription

public enum ProxymanCertificate {
    public static let environmentKey = "PROXYMAN_CA_PEM_BASE64"

    private static let certificateRelativePath = "Library/Application Support/com.proxyman.NSProxy/app-data/proxyman-ca.pem"

    public static var environmentVariables: [String: EnvironmentVariable] {
        let certificateURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(certificateRelativePath)
        guard let certificate = try? Data(contentsOf: certificateURL) else {
            return [:]
        }

        return [environmentKey: .environmentVariable(value: certificate.base64EncodedString(), isEnabled: true)]
    }
}
