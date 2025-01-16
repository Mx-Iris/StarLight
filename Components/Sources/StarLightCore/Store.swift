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

public final class Store: @unchecked Sendable {
    public var repositories: [Repository] {
        get async throws {
            if _repositories.isEmpty {
                try await fetchRepositories()
            }
            return _repositories
        }
    }

    private var _repositories: [Repository] = []

    private var client: GitHubClient

    private var tokenCancellable: AnyCancellable?

    public private(set) var state: State = .idle

    public var completion: (([Repository]) -> Void)?

    public var refreshInterval: TimeInterval = 15 {
        didSet {
            reloadRefreshTimer()
        }
    }

    private var refreshTimer: Timer?

    public enum State {
        case idle
        case fetching
        case loading
    }

    public init() {
        self.client = .init(token: KeychainStorage.token)
        self.tokenCancellable = KeychainStorage.$token.sink { [weak self] token in
            guard let self else { return }
            self.client = .init(token: token)
            Task {
                do {
                    if token != nil {
                        try await self.fetchRepositories()
                    }
                } catch {
                    print(error)
                }
            }
        }
        Task {
            do {
                try await loadRepositories()
            } catch {
                print(error)
            }
        }
        reloadRefreshTimer()
    }

    private func reloadRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task {
                do {
                    try await self.fetchRepositories()
                } catch {
                    print(error)
                }
            }
        }
    }

    private func fetchRepositories() async throws {
        guard state == .idle else { return }
        state = .fetching
        defer { state = .idle }
        let user = try await client.authenticatedUser()
        _repositories = try await client.allUserStarredRepositories(username: user.login, sort: .created, direction: .asc)
        try await saveRepositories()
    }

    private func loadRepositories() async throws {
        guard state == .idle else { return }
        state = .loading
        defer { state = .idle }
        _repositories = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    let repositories = try JSONDecoder().decode([Repository].self, from: Data(contentsOf: self.storageURL))
                    continuation.resume(returning: repositories)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func saveRepositories() async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    try JSONEncoder().encode(self._repositories).write(to: self.storageURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private var storageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "Repositories.json")
    }
}
