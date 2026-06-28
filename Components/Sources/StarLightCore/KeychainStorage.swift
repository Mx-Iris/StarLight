import Foundation
import GitHubModels
import FoundationToolbox

enum Keychains {
    private static let serviceName = "com.JH.StarLight.Keychains"

    @Keychain(key: "token", service: serviceName)
    static var token: Token? = nil
}

extension Token: @retroactive @unchecked Sendable {}
extension Token: @retroactive KeychainCodableStorable {}
