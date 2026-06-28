import AppKit
import Foundation
import Combine
import CocoaCoordinator
import GitHubModels
import StarLightCore

@MainActor
final class LoginViewModel: ViewModel<LoginRoute>, ObservableObject {
    @Published private(set) var deviceCode: DeviceCode?
    @Published private(set) var isAuthorizing: Bool = false
    @Published private(set) var errorMessage: String?

    private var loginTask: Task<Void, Never>?

    override init(appServices: AppServices, router: any Router<LoginRoute>) {
        super.init(appServices: appServices, router: router)
        let service = appServices.loginService
        Task { @MainActor in
            await service.installDelegate(self)
        }
    }

    func startLogin() {
        guard !isAuthorizing else { return }
        errorMessage = nil
        deviceCode = nil
        isAuthorizing = true

        loginTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await appServices.loginService.login()
                guard !Task.isCancelled else { return }
                router.trigger(.logged)
            } catch is CancellationError {
                // User cancelled — silent.
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isAuthorizing = false
            deviceCode = nil
        }
    }

    func cancelLogin() {
        loginTask?.cancel()
        loginTask = nil
        Task { await appServices.loginService.cancelLogin() }
        isAuthorizing = false
        deviceCode = nil
        errorMessage = nil
    }

    func authorizeOnGitHub() {
        guard let deviceCode else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(deviceCode.userCode, forType: .string)
        NSWorkspace.shared.open(deviceCode.verificationURI)
    }

    fileprivate func receive(_ deviceCode: DeviceCode) {
        self.deviceCode = deviceCode
        authorizeOnGitHub()
    }
}

extension LoginViewModel: LoginServiceDelegate {
    nonisolated func loginService(_ service: LoginService, didReceiveDeviceCode deviceCode: DeviceCode) {
        Task { @MainActor in
            receive(deviceCode)
        }
    }
}

extension LoginService {
    func installDelegate(_ delegate: LoginServiceDelegate?) async {
        await MainActor.run {
            self.delegate = delegate
        }
    }
}
