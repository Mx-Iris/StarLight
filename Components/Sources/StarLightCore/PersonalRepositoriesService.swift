import Foundation
import Combine
import GitHubModels
import GitHubNetworking

/// Fetches the repositories the signed-in user owns plus every repository under the organizations
/// they belong to, and caches them next to the starred collection maintained by
/// `StarredRepositoriesService`.
///
/// Three endpoints feed this list:
///
/// 1. `GET /user/repos` with `affiliation=owner,organization_member`
/// 2. `GET /user/orgs`
/// 3. `GET /orgs/{organization}/repos?type=all`, once per organization
///
/// Step 1 is not redundant with step 3. Without the `read:org` scope, `GET /user/orgs` reports only
/// the organizations whose membership the user has made public, so step 1 is what still surfaces
/// repositories from organizations that step 2 cannot see.
public actor PersonalRepositoriesService {
    public var cachedRepositories: [Repository] {
        _repositories
    }

    private var _repositories: [Repository] = []

    private var client: GitHubClient
    private var clientGeneration: UInt = 0
    private var authenticatedUserLogin: String?

    private var cachedAuthenticatedUserLogin: String?
    private var lastFullRefreshDate: Date?

    private var tokenCancellable: AnyCancellable?

    @Published
    public private(set) var state: State = .idle

    @Published
    public private(set) var repositoriesChangeIdentifier: UInt = 0

    /// Off until the app layer pushes the user's preference, so a user who never enables the
    /// feature never causes a request.
    private var isEnabled = false

    public private(set) var refreshInterval: TimeInterval = 15 {
        didSet {
            setupAutoRefresh()
        }
    }

    public func setRefreshInterval(_ interval: TimeInterval) {
        refreshInterval = interval
    }

    public func setEnabled(_ isEnabled: Bool) {
        guard self.isEnabled != isEnabled else { return }
        self.isEnabled = isEnabled

        if isEnabled {
            loadRepositories()
            runFetchRepositoriesTask(isManualRefresh: false)
        } else {
            fetchRepositoriesTask?.cancel()
            fetchRepositoriesTask = nil
            setRepositories([])
        }
    }

    public enum State {
        case idle
        case fetching
        case loading
    }

    private static let repositoriesPerPage = 100
    private static let minimumFullRefreshInterval: TimeInterval = 30 * 60

    /// Backstop against an endpoint that never reports a short page. 100 pages is 10,000
    /// repositories, far past any realistic account.
    private static let maximumPageCount = 100

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
        observeTokenChanges()
        setupAutoRefresh()
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

        // A new token may carry wider scopes than the one that produced the cache, so the next
        // refresh has to walk everything again rather than wait out the throttle.
        lastFullRefreshDate = nil

        if token != nil, isEnabled {
            runFetchRepositoriesTask(isManualRefresh: false)
        }
    }

    public func refresh() {
        guard isEnabled else { return }
        runFetchRepositoriesTask(isManualRefresh: true)
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

                await runAutomaticFetchRepositoriesTaskIfNeeded()
            }
        }
    }

    private func runAutomaticFetchRepositoriesTaskIfNeeded() {
        guard isEnabled, Keychains.token != nil else { return }
        guard PersonalRepositoriesRefreshPolicy.shouldRefresh(
            lastFullRefreshDate: lastFullRefreshDate,
            currentDate: Date(),
            minimumFullRefreshInterval: Self.minimumFullRefreshInterval
        ) else {
            return
        }

        runFetchRepositoriesTask(isManualRefresh: false)
    }

    private var fetchRepositoriesTask: Task<[Repository], Error>?
    private var fetchRepositoriesRequestIdentifier: UInt = 0

    /// A refresh always walks every page, so a manual refresh arriving while one is already running
    /// has nothing extra to do — it joins the running task instead of restarting the work.
    @discardableResult
    private func runFetchRepositoriesTask(isManualRefresh: Bool) -> Task<[Repository], Error> {
        if let fetchRepositoriesTask, !fetchRepositoriesTask.isCancelled {
            return fetchRepositoriesTask
        }

        fetchRepositoriesRequestIdentifier &+= 1
        let requestIdentifier = fetchRepositoriesRequestIdentifier
        let requestClient = client
        let requestClientGeneration = clientGeneration

        let task = Task { [weak self] () throws -> [Repository] in
            guard let self else { throw CancellationError() }
            return try await self.executeFetchRepositoriesTask(
                requestIdentifier: requestIdentifier,
                requestClient: requestClient,
                requestClientGeneration: requestClientGeneration
            )
        }
        fetchRepositoriesTask = task
        return task
    }

    private func executeFetchRepositoriesTask(
        requestIdentifier: UInt,
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> [Repository] {
        state = .fetching
        defer {
            if requestIdentifier == fetchRepositoriesRequestIdentifier {
                state = .idle
                fetchRepositoriesTask = nil
            }
        }

        do {
            return try await fetchRepositories(
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
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> [Repository] {
        try ensureRequestIsCurrent(requestClientGeneration)

        let currentAuthenticatedUserLogin = try await resolveAuthenticatedUserLogin(
            requestClient: requestClient,
            requestClientGeneration: requestClientGeneration
        )

        if cachedAuthenticatedUserLogin != currentAuthenticatedUserLogin {
            setRepositories([])
            cachedAuthenticatedUserLogin = currentAuthenticatedUserLogin
            lastFullRefreshDate = nil
        }

        var mergedRepositories = MergedRepositories()

        mergedRepositories.append(try await fetchAffiliatedRepositories(
            requestClient: requestClient,
            requestClientGeneration: requestClientGeneration
        ))

        for organizationLogin in try await fetchOrganizationLogins(
            requestClient: requestClient,
            requestClientGeneration: requestClientGeneration
        ) {
            mergedRepositories.append(try await fetchRepositories(
                inOrganization: organizationLogin,
                requestClient: requestClient,
                requestClientGeneration: requestClientGeneration
            ))
        }

        let fetchedRepositories = mergedRepositories.repositories
            .sorted { $0.pushedAt > $1.pushedAt }

        setRepositories(fetchedRepositories)
        cachedAuthenticatedUserLogin = currentAuthenticatedUserLogin
        lastFullRefreshDate = Date()
        saveRepositories()
        return fetchedRepositories
    }

    private func fetchAffiliatedRepositories(
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> [Repository] {
        try await fetchAllPages(requestClientGeneration: requestClientGeneration) { pageNumber in
            // `visibility` and `affiliation` cannot be combined with `type`; GitHub answers 422.
            try await requestClient.authenticatedUserRepositories(
                filter: .visibilityAndAffiliation(.all, [.owner, .organizationMember]),
                sort: .pushed,
                direction: .desc,
                numberOfPerPage: Self.repositoriesPerPage,
                page: pageNumber,
                since: nil,
                before: nil
            )
        }
    }

    private func fetchOrganizationLogins(
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> [String] {
        // `isDetail` would issue one extra request per organization behind a blocking semaphore,
        // and the login is all this service needs.
        let organizations = try await fetchAllPages(requestClientGeneration: requestClientGeneration) { pageNumber in
            try await requestClient.authenticatedUserOrganizations(
                numberOfPerPage: Self.repositoriesPerPage,
                page: pageNumber,
                isDetail: false
            )
        }

        return organizations.map(\.login)
    }

    private func fetchRepositories(
        inOrganization organizationLogin: String,
        requestClient: GitHubClient,
        requestClientGeneration: UInt
    ) async throws -> [Repository] {
        do {
            return try await fetchAllPages(requestClientGeneration: requestClientGeneration) { pageNumber in
                try await requestClient.organizationRepositories(
                    organization: organizationLogin,
                    type: .all,
                    sort: .pushed,
                    direction: .desc,
                    numberOfPerPage: Self.repositoriesPerPage,
                    page: pageNumber
                )
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // One organization the token cannot list — restricted by SAML, or by an owner who
            // limited third-party access — must not cost the user every other organization.
            guard !AuthenticationFailureReporter.isAuthenticationFailure(error) else { throw error }
            print("Skipping organization \(organizationLogin): \(error)")
            return []
        }
    }

    private func fetchAllPages<Element>(
        requestClientGeneration: UInt,
        fetchPage: (Int) async throws -> [Element]
    ) async throws -> [Element] {
        var elements: [Element] = []

        for pageNumber in 1 ... Self.maximumPageCount {
            try ensureRequestIsCurrent(requestClientGeneration)
            let pageElements = try await fetchPage(pageNumber)
            try ensureRequestIsCurrent(requestClientGeneration)

            elements.append(contentsOf: pageElements)
            guard pageElements.count == Self.repositoriesPerPage else { break }
        }

        return elements
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

    private func ensureRequestIsCurrent(_ requestClientGeneration: UInt) throws {
        try Task.checkCancellation()
        guard requestClientGeneration == clientGeneration else {
            throw CancellationError()
        }
    }

    private func setRepositories(_ repositories: [Repository]) {
        _repositories = repositories
        repositoriesChangeIdentifier &+= 1
    }

    /// Accumulates repositories from the three endpoints, dropping the overlap between them —
    /// a repository you own inside one of your organizations arrives from two of the three.
    private struct MergedRepositories {
        private(set) var repositories: [Repository] = []
        private var seenFullnames: Set<String> = []

        mutating func append(_ repositoriesToAppend: [Repository]) {
            for repository in repositoriesToAppend where seenFullnames.insert(repository.fullname).inserted {
                repositories.append(repository)
            }
        }
    }

    private struct RepositoryCacheMetadata: Codable {
        let authenticatedUserLogin: String?
        let lastFullRefreshDate: Date?
    }

    private func loadRepositories() {
        state = .loading
        defer { state = .idle }

        do {
            let decoder = JSONDecoder()
            setRepositories(try decoder.decode([Repository].self, from: Data(contentsOf: storageURL)))
            loadRepositoryCacheMetadata(using: decoder)
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
        } catch {
            print(error)
        }
    }

    private static let storageFileName = "PersonalRepositories.json"
    private static let metadataStorageFileName = "PersonalRepositoriesMetadata.json"

    private var storageURL: URL {
        RepositoryCacheLocation.storageURL(forFileNamed: Self.storageFileName)
    }

    private var metadataStorageURL: URL {
        RepositoryCacheLocation.storageURL(forFileNamed: Self.metadataStorageFileName)
    }
}
