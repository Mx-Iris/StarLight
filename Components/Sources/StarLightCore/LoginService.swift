//
//  LoginService.swift
//  Components
//
//  Created by JH on 2025/1/3.
//

import Foundation
import GitHubNetworking
@preconcurrency import AuthenticationServices

public final class LoginService: @unchecked Sendable {
    public init() {}

    private var authSession: ASWebAuthenticationSession?

    private let presentationContextProvider = WebAuthenticationPresentationContextProvidingCoordinator()

    public var hasLogin: Bool {
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
                        GitHubClient.createAccessToken(clientId: Configs.App.githubID, clientSecret: Configs.App.githubSecrets, code: code, redirectURI: nil, state: nil) { result in
                            switch result {
                            case let .success(token):
                                continuation.resume(returning: token)
                            case let .failure(error):
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
}

private class WebAuthenticationPresentationContextProvidingCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
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
