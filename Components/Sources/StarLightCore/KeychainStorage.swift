import Foundation
import GitHubModels
import StarLightUtilities

enum KeychainStorage {
    private static let serviceName = "com.JH.StarLight.KeychainStorage"

    @Keychain(key: "token", service: serviceName)
    static var token: Token? = nil
}
