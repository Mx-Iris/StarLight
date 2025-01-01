//
//  Store.swift
//  StarLight
//
//  Created by JH on 2024/12/29.
//

import Foundation
import GitHubModels
import GitHubNetworking
import StarLightUtilities
@preconcurrency import AuthenticationServices

public final class Store {
    public private(set) var repositories: [Repository] = []

    private var client: GitHubClient

    public init(token: Token) {
        self.client = .init(token: token)
    }

    public func fetchRepositories() async throws {
        let user = try await client.authenticatedUser()
        repositories = try await client.allUserStarredRepositories(username: user.login, sort: .created, direction: .asc)
    }
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

public final class UserManager: @unchecked Sendable {
//    public static let shared = UserManager()

    public init() {}

    private var authSession: ASWebAuthenticationSession?

    private let presentationContextProvider = WebAuthenticationPresentationContextProvidingCoordinator()

    @Keychain(key: "token", service: "StarLightCore-UserManager", defaultValue: nil)
    public private(set) var token: Token?

    @UserDefault(defaultValue: nil)
    public private(set) var user: User?

    public var hasLogin: Bool {
        token != nil
    }

    public func login() async throws {
        enum UnknownError: Error {
            case unknownError
        }

        token = try await withCheckedThrowingContinuation { continuation in
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
        user = try await GitHubClient(token: token).authenticatedUser()
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

extension User: @retroactive UserDefaultSerializable {}
