import Foundation
import GitHubNetworking
@preconcurrency import AuthenticationServices

public actor LoginService {
    public init() {}

    @MainActor
    private var authSession: ASWebAuthenticationSession?

    @MainActor
    private let presentationContextProvider = WebAuthenticationPresentationContextProvidingCoordinator()

    public nonisolated var hasLogin: Bool {
        KeychainStorage.token != nil
    }

    public func login() async throws {
        enum UnknownError: Error {
            case unknownError
        }

        KeychainStorage.token = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async { [self] in
                let authSession = ASWebAuthenticationSession(url: Configs.App.githubLoginURL, callbackURLScheme: Configs.App.urlScheme, completionHandler: { url, error in
                    if let code = url?.queryParameters?["code"] {
                        GitHubClient.accessToken(clientID: Configs.App.githubID, clientSecret: Configs.App.githubSecrets, code: code, redirectURI: nil, state: nil) { result in
                            switch result {
                            case .success(let token):
                                continuation.resume(returning: token)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                    } else if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: UnknownError.unknownError)
                    }

                })
                authSession.presentationContextProvider = presentationContextProvider
                authSession.prefersEphemeralWebBrowserSession = true
                authSession.start()
                self.authSession = authSession
            }
        }
    }

    public nonisolated func logout() {
        KeychainStorage.token = nil
    }
}

private final class WebAuthenticationPresentationContextProvidingCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.orderedWindows.first!
    }
}

extension URL {
    fileprivate var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return nil }

        var items: [String: String] = [:]

        for queryItem in queryItems {
            items[queryItem.name] = queryItem.value
        }

        return items
    }
}
