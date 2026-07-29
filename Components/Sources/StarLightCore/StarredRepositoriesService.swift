import Foundation
import Combine
import GitHubModels
import GitHubNetworking

public actor StarredRepositoriesService {
    public var repositories: [Repository] {
        get async throws {
            if let fetchRepositoriesTask, !fetchRepositoriesTask.isCancelled {
                return try await fetchRepositoriesTask.value
            } else if _repositories.isEmpty, client.isAuthorized {
                return try await runFetchRepositoriesTask(forceFullRefresh: true).value
            } else {
                return _repositories
            }
        }
    }

    public var cachedRepositories: [Repository] {
        _repositories
    }

    private var _repositories: [Repository] = []

    private var client: GitHubClient
    private var clientGeneration: UInt = 0
    private var authenticatedUserLogin: String?

    private var cachedAuthenticatedUserLogin: String?
    private var lastFullRefreshDate: Date?
    private var repositoryCacheRequiresPersistenceMigration = false

    private var tokenCancellable: AnyCancellable?

    @Published
    public private(set) var state: State = .idle

    @Published
    public private(set) var repositoriesChangeIdentifier: UInt = 0

    public private(set) var refreshInterval: TimeInterval = 15 {
        didSet {
            setupAutoRefresh()
        }
    }

    public func setRefreshInterval(_ interval: TimeInterval) {
        refreshInterval = interval
    }

    public enum State {
        case idle
        case fetching
        case loading
    }

    private static let repositoriesPerPage = 100
    private static let maximumFullRefreshAge: TimeInterval = 24 * 60 * 60

    public init() {
        client = .init(token: Keychains.token)
        Task {
            await initialize()
        }
    }

    deinit {
        refreshLoopTask?.cancel()
        fetchRepositoriesTask?.cancel()
        tokenCancellable?.cancel()
    }

    private func initialize() {
        state = .loading
        loadRepositories()
        state = .idle

        observeTokenChanges()
        setupAutoRefresh()

        if Keychains.token != nil {
            runFetchRepositoriesTask(forceFullRefresh: false)
        }
    }

    private func observeTokenChanges() {
        tokenCancellable = Keychains.$token.sink { [weak self] token in
            guard let self else { return }
            Task {
                await self.updateClient(for: token)
            }
        }
    }

    private func updateClient(for token: Token?) {
        clientGeneration &+= 1
        fetchRepositoriesTask?.cancel()
        client = .init(token: token)
        authenticatedUserLogin = nil

        if token != nil {
            runFetchRepositoriesTask(forceFullRefresh: false)
        }
    }

    public func refresh() {
        runFetchRepositoriesTask(forceFullRefresh: true)
    }

    private var refreshLoopTask: Task<Void, Never>?

    private func setupAutoRefresh() {
        refreshLoopTask?.cancel()

        let refreshIntervalNanoseconds = UInt64(refreshInterval * 60 * 1_000_000_000)

        refreshLoopTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: refreshIntervalNanoseconds)
                guard let self else { return }
                if Task.isCancelled { return }

                await runFetchRepositoriesTask(forceFullRefresh: false)
            }
        }
    }

    private var fetchRepositoriesTask: Task<[Repository], Error>?
    private var fetchRepositoriesRequestIdentifier: UInt = 0
    private var fetchRepositoriesTaskPerformsFullRefresh = false

    @discardableResult
    private func runFetchRepositoriesTask(forceFullRefresh: Bool) -> Task<[Repository], Error> {
        let taskToAwaitBeforeStarting: Task<[Repository], Error>?
        if let fetchRepositoriesTask {
            if !fetchRepositoriesTask.isCancelled {
                guard StarredRepositoriesRefreshPolicy.shouldReplaceRunningRefresh(
                    requestedRefreshForcesFullRefresh: forceFullRefresh,
                    runningRefreshPerformsFullRefresh: fetchRepositoriesTaskPerformsFullRefresh
                ) else {
                    return fetchRepositoriesTask
                }
                fetchRepositoriesTask.cancel()
            }
            taskToAwaitBeforeStarting = fetchRepositoriesTask
        } else {
            taskToAwaitBeforeStarting = nil
        }

        fetchRepositoriesRequestIdentifier &+= 1
        let requestIdentifier = fetchRepositoriesRequestIdentifier
        let requestClient = client
        let requestClientGeneration = clientGeneration

        let task = Task { [weak self] () throws -> [Repository] in
            guard let self else { throw CancellationError() }
            return try await self.executeFetchRepositoriesTask(
                forceFullRefresh: forceFullRefresh,
                requestIdentifier: requestIdentifier,
                requestClient: requestClient,
                requestClientGeneration: requestClientGeneration,
                taskToAwaitBeforeStarting: taskToAwaitBeforeStarting
            )
        }
        fetchRepositoriesTask = task
        fetchRepositoriesTaskPerformsFullRefresh = forceFullRefresh
        return task
    }

    private func executeFetchRepositoriesTask(
        forceFullRefresh: Bool,
        requestIdentifier: UInt,
        requestClient: GitHubClient,
        requestClientGeneration: UInt,
        taskToAwaitBeforeStarting: Task<[Repository], Error>?
    ) async throws -> [Repository] {
        state = .fetching
        defer {
            if requestIdentifier == fetchRepositoriesRequestIdentifier {
                state = .idle
                fetchRepositoriesTask = nil
                fetchRepositoriesTaskPerformsFullRefresh = false
            }
        }

        if let taskToAwaitBeforeStarting {
            _ = try? await taskToAwaitBeforeStarting.value
            try ensureRequestIsCurrent(requestClientGeneration)
        }

        do {
            return try await fetchRepositories(
                forceFullRefresh: forceFullRefresh,
                requestClient: requestClient,
                requestClientGeneration: requestClientGeneration
            )
        } catch {
            if !(error is CancellationError) {
                print(error)
                await AuthenticationFailureReporter.reportIfNeeded(error)
            }
            throw error
        }
    }

    private func fetchRepositories(
        forceFullRefresh: Bool,
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> [Repository] {
        try ensureRequestIsCurrent(requestClientGeneration)

        let currentAuthenticatedUserLogin = try await resolveAuthenticatedUserLogin(
            requestClient: requestClient,
            requestClientGeneration: requestClientGeneration
        )
        let cacheBelongsToAuthenticatedUser = cachedAuthenticatedUserLogin == currentAuthenticatedUserLogin

        if !cacheBelongsToAuthenticatedUser {
            setRepositories([])
            cachedAuthenticatedUserLogin = currentAuthenticatedUserLogin
            lastFullRefreshDate = nil
        }

        let firstPageResponse = try await fetchRepositoriesPage(
            pageNumber: 1,
            requestClient: requestClient,
            requestClientGeneration: requestClientGeneration
        )

        let currentDate = Date()
        let shouldPerformFullRefresh = forceFullRefresh
            || !cacheBelongsToAuthenticatedUser
            || _repositories.isEmpty
            || StarredRepositoriesRefreshPolicy.shouldPerformFullRefresh(
                lastFullRefreshDate: lastFullRefreshDate,
                currentDate: currentDate,
                maximumFullRefreshAge: Self.maximumFullRefreshAge
            )

        if shouldPerformFullRefresh {
            fetchRepositoriesTaskPerformsFullRefresh = true
            return try await performFullRefresh(
                firstPageResponse: firstPageResponse,
                authenticatedUserLogin: currentAuthenticatedUserLogin,
                requestClient: requestClient,
                requestClientGeneration: requestClientGeneration
            )
        }

        let membershipChanged = try await repositoryMembershipChanged(
            firstPageResponse: firstPageResponse,
            requestClient: requestClient,
            requestClientGeneration: requestClientGeneration
        )

        if membershipChanged {
            fetchRepositoriesTaskPerformsFullRefresh = true
            return try await performFullRefresh(
                firstPageResponse: firstPageResponse,
                authenticatedUserLogin: currentAuthenticatedUserLogin,
                requestClient: requestClient,
                requestClientGeneration: requestClientGeneration
            )
        }

        if repositoryCacheRequiresPersistenceMigration {
            saveRepositories()
        }
        return _repositories
    }

    private func resolveAuthenticatedUserLogin(
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> String {
        if let authenticatedUserLogin {
            return authenticatedUserLogin
        }

        let user = try await requestClient.authenticatedUser()
        try ensureRequestIsCurrent(requestClientGeneration)
        authenticatedUserLogin = user.login
        return user.login
    }

    private func repositoryMembershipChanged(
        firstPageResponse: PaginatedResponse<Repository>,
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> Bool {
        let lastPageNumber: Int
        if let responseLastPageNumber = firstPageResponse.lastPageNumber {
            lastPageNumber = responseLastPageNumber
        } else if firstPageResponse.nextPageNumber == nil {
            lastPageNumber = 1
        } else {
            return true
        }

        let remoteRepositoryCount: Int
        if lastPageNumber == 1 {
            remoteRepositoryCount = firstPageResponse.elements.count
        } else {
            let lastPageResponse = try await fetchRepositoriesPage(
                pageNumber: lastPageNumber,
                requestClient: requestClient,
                requestClientGeneration: requestClientGeneration
            )
            remoteRepositoryCount = ((lastPageNumber - 1) * Self.repositoriesPerPage) + lastPageResponse.elements.count
        }

        return StarredRepositoriesRefreshPolicy.repositoryMembershipChanged(
            cachedRepositoryNames: _repositories.map(\.fullname),
            firstPageRepositoryNames: firstPageResponse.elements.map(\.fullname),
            remoteRepositoryCount: remoteRepositoryCount
        )
    }

    private func performFullRefresh(
        firstPageResponse: PaginatedResponse<Repository>,
        authenticatedUserLogin: String,
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> [Repository] {
        mergeFirstPageIntoCachedRepositories(firstPageResponse.elements)

        var fetchedRepositories = firstPageResponse.elements
        var currentPageResponse = firstPageResponse

        while let nextPageNumber = currentPageResponse.nextPageNumber {
            currentPageResponse = try await fetchRepositoriesPage(
                pageNumber: nextPageNumber,
                requestClient: requestClient,
                requestClientGeneration: requestClientGeneration
            )
            fetchedRepositories.append(contentsOf: currentPageResponse.elements)
        }

        setRepositories(fetchedRepositories)
        cachedAuthenticatedUserLogin = authenticatedUserLogin
        lastFullRefreshDate = Date()
        saveRepositories()
        return fetchedRepositories
    }

    private func fetchRepositoriesPage(
        pageNumber: Int,
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> PaginatedResponse<Repository> {
        let response = try await requestClient.authenticatedUserStarredRepositories(
            sort: .created,
            direction: .desc,
            numberOfPerPage: Self.repositoriesPerPage,
            page: pageNumber,
            entityTag: nil
        )
        try ensureRequestIsCurrent(requestClientGeneration)

        guard !response.isNotModified else {
            throw StarredRepositoriesServiceError.unexpectedNotModifiedResponse
        }
        return response
    }

    private func ensureRequestIsCurrent(_ requestClientGeneration: UInt) throws {
        try Task.checkCancellation()
        guard requestClientGeneration == clientGeneration else {
            throw CancellationError()
        }
    }

    private func mergeFirstPageIntoCachedRepositories(_ firstPageRepositories: [Repository]) {
        let firstPageRepositoryNames = Set(firstPageRepositories.map(\.fullname))
        let remainingCachedRepositories = _repositories.filter {
            !firstPageRepositoryNames.contains($0.fullname)
        }
        setRepositories(firstPageRepositories + remainingCachedRepositories)
    }

    private func setRepositories(_ repositories: [Repository]) {
        _repositories = repositories
        repositoriesChangeIdentifier &+= 1
    }

    private struct RepositoryCacheEnvelope: Codable {
        let repositories: [Repository]
        let authenticatedUserLogin: String?
        let lastFullRefreshDate: Date?
    }

    private struct RepositoryCacheMetadata: Codable {
        let authenticatedUserLogin: String?
        let lastFullRefreshDate: Date?
    }

    private func loadRepositories() {
        migrateLegacyStorageIfNeeded()

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()

            if let repositories = try? decoder.decode([Repository].self, from: data) {
                setRepositories(repositories)
                repositoryCacheRequiresPersistenceMigration = false
                loadRepositoryCacheMetadata(using: decoder)
            } else if let repositoryCacheEnvelope = try? decoder.decode(RepositoryCacheEnvelope.self, from: data) {
                setRepositories(repositoryCacheEnvelope.repositories)
                cachedAuthenticatedUserLogin = repositoryCacheEnvelope.authenticatedUserLogin
                lastFullRefreshDate = repositoryCacheEnvelope.lastFullRefreshDate
                repositoryCacheRequiresPersistenceMigration = true
            } else {
                setRepositories(try decoder.decode([Repository].self, from: data))
            }
        } catch {
            print(error)
        }
    }

    private func loadRepositoryCacheMetadata(using decoder: JSONDecoder) {
        do {
            let metadata = try decoder.decode(
                RepositoryCacheMetadata.self,
                from: Data(contentsOf: metadataStorageURL)
            )
            cachedAuthenticatedUserLogin = metadata.authenticatedUserLogin
            lastFullRefreshDate = metadata.lastFullRefreshDate
        } catch {
            cachedAuthenticatedUserLogin = nil
            lastFullRefreshDate = nil
        }
    }

    private func saveRepositories() {
        let metadata = RepositoryCacheMetadata(
            authenticatedUserLogin: cachedAuthenticatedUserLogin,
            lastFullRefreshDate: lastFullRefreshDate
        )

        do {
            let encoder = JSONEncoder()
            try encoder.encode(_repositories).write(to: storageURL, options: .atomic)
            try encoder.encode(metadata).write(to: metadataStorageURL, options: .atomic)
            repositoryCacheRequiresPersistenceMigration = false
        } catch {
            print(error)
        }
    }

    private static let storageFileName = "StarredRepositories.json"
    private static let metadataStorageFileName = "StarredRepositoriesMetadata.json"

    /// Builds up to and including 1.7 wrote these caches under names that did not say which
    /// repository collection they held. Now that a second collection exists, the files carry the
    /// `Starred` prefix, and older caches are moved across instead of being refetched.
    private static let legacyStorageFileName = "Repositories.json"
    private static let legacyMetadataStorageFileName = "RepositoriesMetadata.json"

    private func migrateLegacyStorageIfNeeded() {
        RepositoryCacheLocation.migrateLegacyStorage(
            from: Self.legacyStorageFileName,
            to: Self.storageFileName
        )
        RepositoryCacheLocation.migrateLegacyStorage(
            from: Self.legacyMetadataStorageFileName,
            to: Self.metadataStorageFileName
        )
    }

    private var storageURL: URL {
        RepositoryCacheLocation.storageURL(forFileNamed: Self.storageFileName)
    }

    private var metadataStorageURL: URL {
        RepositoryCacheLocation.storageURL(forFileNamed: Self.metadataStorageFileName)
    }

    private enum StarredRepositoriesServiceError: Error {
        case unexpectedNotModifiedResponse
    }
}
