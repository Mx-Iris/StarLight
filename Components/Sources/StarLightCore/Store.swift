//
//  Store.swift
//  StarLight
//
//  Created by JH on 2024/12/29.
//

import Foundation
import Combine
import GitHubModels
import GitHubNetworking

public final class Store {
    @Published
    public private(set) var repositories: [Repository] = []

    private var client: GitHubClient

    private var tokenCancellable: AnyCancellable?

    public init() {
        self.client = .init(token: KeychainStorage.token)
        self.tokenCancellable = KeychainStorage.$token.sink { [weak self] token in
            guard let self else { return }
            self.client = .init(token: token)
            Task {
                do {
                    try await self.fetchRepositories()
                } catch {
                    print(error)
                }
            }
        }
    }

    public func fetchRepositories() async throws {
        let user = try await client.authenticatedUser()
        repositories = try await client.allUserStarredRepositories(username: user.login, sort: .created, direction: .asc)
    }
}
