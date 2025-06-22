import Foundation
import Combine
import GitHubModels
import GitHubNetworking

public actor RepositoriesService {
    public var repositories: [Repository] {
        get async throws {
            if let fetchRepositoriesTask, !fetchRepositoriesTask.isCancelled {
                return try await fetchRepositoriesTask.value
            } else if _repositories.isEmpty {
                return try await runFetchRepositoriesTask().value
            } else {
                return _repositories
            }
        }
    }

    private var _repositories: [Repository] = []

    private var client: GitHubClient

    private var tokenCancellable: AnyCancellable?

    @Published
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
        Task {
            await observeTokenChanges()
            await reloadRefreshTimer()
        }
        Task.detached { [self] in
            do {
                try await loadRepositories()
            } catch {
                print(error)
            }
        }
    }

    private func observeTokenChanges() {
        tokenCancellable = KeychainStorage.$token.sink { [weak self] token in
            guard let self else { return }
            Task {
                await self.updateClient(for: token)
            }
        }
    }
    
    private func updateClient(for token: Token?) {
        self.client = .init(token: token)
        if token != nil {
            self.runFetchRepositoriesTask()
        }
    }
    
    public func refresh() {
        runFetchRepositoriesTask()
    }

    private func reloadRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.runFetchRepositoriesTask()
            }
        }
    }

    private var fetchRepositoriesTask: Task<[Repository], Error>?

    @discardableResult
    private func runFetchRepositoriesTask() -> Task<[Repository], Error> {
        if let fetchRepositoriesTask, !fetchRepositoriesTask.isCancelled {
            return fetchRepositoriesTask
        }
        let task: Task<[Repository], Error> = Task {
            do {
                return try await fetchRepositories()
            } catch {
                print(error)
                throw error
            }
        }
        fetchRepositoriesTask = task
        return task
    }

    private func fetchRepositories() async throws -> [Repository] {
        state = .fetching
        defer {
            state = .idle
            fetchRepositoriesTask = nil
        }
        let user = try await client.authenticatedUser()
        let repositories = try await client.allUserStarredRepositories(username: user.login, sort: .created, direction: .asc)
        _repositories = repositories
        try await saveRepositories()
        return repositories
    }

    private func loadRepositories() async throws {
        state = .loading
        defer { state = .idle }
        _repositories = try JSONDecoder().decode([Repository].self, from: Data(contentsOf: storageURL))
    }

    private func saveRepositories() async throws {
        try JSONEncoder().encode(_repositories).write(to: storageURL)
    }

    private var storageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "Repositories.json")
    }
}
