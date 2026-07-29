import Foundation
import GitHubNetworking

extension Foundation.Notification.Name {
    /// Posted when GitHub rejects the stored token. Every repository service reports through this
    /// single notification, and `AppCoordinator` answers it by routing back to the login screen.
    public static let gitHubAuthenticationFailed = Foundation.Notification.Name("gitHubAuthenticationFailed")
}

enum AuthenticationFailureReporter {
    private static let authenticationFailureMessages = [
        "Bad credentials",
        "Requires authentication",
        "Resource not accessible by personal access token",
    ]

    static func isAuthenticationFailure(message: String?) -> Bool {
        guard let message else { return false }
        return authenticationFailureMessages.contains { message.localizedCaseInsensitiveContains($0) }
    }

    static func isAuthenticationFailure(_ error: Error) -> Bool {
        guard let apiError = error as? APIError,
              case .serverError(let response) = apiError else {
            return false
        }
        return isAuthenticationFailure(message: response.message)
    }

    /// Discards the stored token and tells the app to ask for a new one, but only for errors that
    /// really are the token being rejected — a network blip must never log the user out.
    static func reportIfNeeded(_ error: Error) async {
        guard isAuthenticationFailure(error) else { return }

        Keychains.token = nil
        await MainActor.run {
            NotificationCenter.default.post(name: .gitHubAuthenticationFailed, object: nil)
        }
    }
}
