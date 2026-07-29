import AppKit
import Foundation
import SwiftUI
import Combine
import CocoaCoordinator
import Defaults
import StarLightCore

@MainActor
final class SettingsViewModel: ViewModel<SettingsRoute>, ObservableObject {
    /// True when the user asked for private repositories but the stored token was granted before
    /// that choice, so GitHub is still withholding them.
    @Published private(set) var needsReauthorizationForPrivateRepositories = false

    @Published var isPresentingPrivateRepositoryAuthorizationAlert = false

    private var authorizationSubscription: AnyCancellable?

    override init(appServices: AppServices, router: any Router<SettingsRoute>) {
        super.init(appServices: appServices, router: router)
        refreshAuthorizationState()

        authorizationSubscription = appServices.loginService.authorizationDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.refreshAuthorizationState()
            }
    }

    func refreshAuthorizationState() {
        needsReauthorizationForPrivateRepositories = Defaults[.includePrivateRepositories]
            && !appServices.loginService.hasGrantedAccess(for: .includingPrivateRepositories)
    }

    func searchPersonalRepositoriesDidChange(to isEnabled: Bool) {
        Task {
            await appServices.personalRepositoriesService.setEnabled(isEnabled)
        }
    }

    func includePrivateRepositoriesDidChange(to isIncluded: Bool) {
        needsReauthorizationForPrivateRepositories = isIncluded
            && !appServices.loginService.hasGrantedAccess(for: .includingPrivateRepositories)

        guard needsReauthorizationForPrivateRepositories else { return }
        isPresentingPrivateRepositoryAuthorizationAlert = true
    }

    func repositoriesRefreshIntervalDidChange(to interval: Double) {
        Task {
            await appServices.starredRepositoriesService.setRefreshInterval(interval)
            await appServices.personalRepositoriesService.setRefreshInterval(interval)
        }
    }

    func reauthorize() {
        router.trigger(.reauthorize)
    }

    /// Declining the wider grant turns the preference back off, so the toggle never claims to be
    /// doing something GitHub has not actually authorized.
    func declinePrivateRepositoryAuthorization() {
        Defaults[.includePrivateRepositories] = false
        refreshAuthorizationState()
    }

    func logout() {
        appServices.loginService.logout()
        router.trigger(.logout)
    }

    func manageAuthorizationsOnGitHub() {
        NSWorkspace.shared.open(LoginService.manageAuthorizationURL)
    }
}
