import Foundation
import Combine
import GitHubModels
import GitHubNetworking

@MainActor
public protocol LoginServiceDelegate: AnyObject {
    func loginService(_ service: LoginService, didReceiveDeviceCode deviceCode: DeviceCode)
}

public actor LoginService {
    public init() {}

    @MainActor
    public weak var delegate: LoginServiceDelegate?

    public nonisolated var hasLogin: Bool {
        Keychains.token != nil
    }

    /// Fires whenever the stored token is replaced or cleared, so screens showing what the current
    /// authorization allows can refresh themselves without being told to.
    public nonisolated var authorizationDidChange: AnyPublisher<Void, Never> {
        Keychains.$token
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Whether the stored token already carries everything the given access level needs. A token
    /// granted before the user opted into private repositories will not, which is what drives the
    /// reauthorization prompt in Settings.
    public nonisolated func hasGrantedAccess(for accessLevel: RepositoryAccessLevel) -> Bool {
        OAuthScopeSatisfaction.grantedScopeString(
            Keychains.token?.scope,
            satisfies: accessLevel.scopes
        )
    }

    private var loginTask: Task<Token, Error>?

    public func login(accessLevel: RepositoryAccessLevel) async throws {
        loginTask?.cancel()

        let service = self
        let task = Task { () throws -> Token in
            try await GitHubClient.deviceFlowLogin(
                clientID: Configs.App.githubID,
                scopes: accessLevel.scopes,
                onUserCode: { deviceCode in
                    Task { await service.publishDeviceCode(deviceCode) }
                }
            )
        }
        loginTask = task

        defer { loginTask = nil }
        let token = try await task.value
        Keychains.token = token
    }

    public func cancelLogin() {
        loginTask?.cancel()
        loginTask = nil
    }

    public nonisolated func logout() {
        Keychains.token = nil
    }

    /// The user-facing URL where users can review or revoke this app's authorization on GitHub.
    /// Shown from Settings as the "Manage on GitHub" affiliate of `logout()`, since dropping the
    /// client secret means we no longer call `DELETE /applications/{client_id}/token` ourselves.
    public nonisolated static var manageAuthorizationURL: URL {
        URL(string: "https://github.com/settings/connections/applications/\(Configs.App.githubID)")!
    }

    private func publishDeviceCode(_ deviceCode: DeviceCode) async {
        await MainActor.run { [weak self] in
            guard let self else { return }
            self.delegate?.loginService(self, didReceiveDeviceCode: deviceCode)
        }
    }
}
