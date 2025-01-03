//
//  KeychainStorage.swift
//  Components
//
//  Created by JH on 2025/1/3.
//

import Foundation
import GitHubModels
import StarLightUtilities

enum KeychainStorage {
    private static let serviceName = "com.JH.StarLight.KeychainStorage"

    @Keychain(key: "token", service: serviceName, defaultValue: nil)
    public static var token: Token?
}
