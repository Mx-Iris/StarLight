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

    public private(set) var refreshInterval: TimeInterval = 15 {
        didSet {
            setupAutoRefresh()
        }
    }

    public func setRefreshInterval(_ interval: TimeInterval) {
        refreshInterval = interval
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
            await setupAutoRefresh()
            await loadRepositories()
        }
    }

    deinit {
        refreshLoopTask?.cancel()
        tokenCancellable?.cancel()
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
        client = .init(token: token)
        if token != nil {
            runFetchRepositoriesTask()
        }
    }

    public func refresh() {
        runFetchRepositoriesTask()
    }

    private var refreshLoopTask: Task<Void, Never>?

    private func setupAutoRefresh() {
        refreshLoopTask?.cancel()

        let intervalNano = UInt64(refreshInterval * 60 * 1_000_000_000)

        refreshLoopTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: intervalNano)
                guard let self else { return }
                if Task.isCancelled { return }

                await runFetchRepositoriesTask()
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
        await saveRepositories()
        return repositories
    }

    @concurrent
    private func loadRepositories() async {
        await setState(.loading)
        defer {
            Task {
                await setState(.idle)
            }
        }
        do {
            try await setRepositories(await JSONDecoder().decode([Repository].self, from: Data(contentsOf: storageURL)))
        } catch {
            print(error)
        }
    }

    @concurrent
    private func saveRepositories() async {
        do {
            try await JSONEncoder().encode(_repositories).write(to: storageURL)
        } catch {
            print(error)
        }
    }

    private func setState(_ state: State) async {
        self.state = state
    }

    private func setRepositories(_ repositories: [Repository]) async {
        _repositories = repositories
    }

    private var storageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "Repositories.json")
    }
}
