import Foundation
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

    private var loginTask: Task<Token, Error>?

    public func login() async throws {
        loginTask?.cancel()

        let service = self
        let task = Task { () throws -> Token in
            try await GitHubClient.deviceFlowLogin(
                clientID: Configs.App.githubID,
                scopes: Configs.App.githubScopes,
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
