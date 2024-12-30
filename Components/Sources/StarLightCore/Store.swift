//
//  Store.swift
//  StarLight
//
//  Created by JH on 2024/12/29.
//

import Foundation
import GitHubModels
import GitHubNetworking
import AuthenticationServices

final class Store {
    private(set) var repositories: [Repository] = []

    private var client: GitHubClient?

    init() {}
}

public enum Configs {
    public enum App {
        public static let urlScheme = "starlight"
        public static let githubID = "Ov23li4DKEAP9Ghz5xtx"
        public static let githubSecrets = "05cb9608345ba9245836ff48ae64d8f9c9b5f62c"
        public static let githubScopes: [OAuthScope] = [.readUser, .publicRepo]
        public static let githubLoginURL = URL(string: "http://github.com/login/oauth/authorize?client_id=\(githubID)&scope=\(githubScopes.scopesString)")!
    }
}

public final class UserManager {
    public static let shared = UserManager()
    private init() {}
    private var authSession: ASWebAuthenticationSession?
    private let presentationContextProvider = WebAuthenticationPresentationContextProvidingCoordinator()
    public func startAuthentication() async throws -> Token {
        enum UnknownError: Error {
            case unknownError
        }

        return try await withCheckedThrowingContinuation { continuation in
            authSession = ASWebAuthenticationSession(url: Configs.App.githubLoginURL, callbackURLScheme: Configs.App.urlScheme, completionHandler: { url, error in
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
            authSession?.presentationContextProvider = presentationContextProvider
            authSession?.prefersEphemeralWebBrowserSession = true
            authSession?.start()
        }
    }
}

private class WebAuthenticationPresentationContextProvidingCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.orderedWindows.first!
    }
}

extension URL {
    /// SwifterSwift: Dictionary of the URL's query parameters
    public var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return nil }

        var items: [String: String] = [:]

        for queryItem in queryItems {
            items[queryItem.name] = queryItem.value
        }

        return items
    }
}
