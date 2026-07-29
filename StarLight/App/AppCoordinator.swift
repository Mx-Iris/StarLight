//
//  AppCoordinator.swift
//  StarLight
//
//  Created by JH on 2024/12/31.
//

import AppKit
import GitHubModels
import CocoaCoordinator
import StarLightCore
import Defaults
import KeyboardShortcuts

enum AppRoute: Routable {
    case login
    case authenticationFailed
    /// Sign in again to widen the granted scopes — the user turned on private repository search
    /// and the stored token predates that choice.
    case reauthorize
    case settings
    case main
    case refresh

    var requiresAuthentication: Bool {
        switch self {
        case .login, .authenticationFailed, .reauthorize:
            false
        case .settings, .main, .refresh:
            true
        }
    }
}

final class AppCoordinator: CocoaCoordinator.AppCoordinator<AppRoute> {
    let appServices: AppServices

    let mainCoordinator: MainCoordinator

    init(appServices: AppServices) {
        self.appServices = appServices
        self.mainCoordinator = MainCoordinator(appServices: appServices)
        var initialRoute: AppRoute?
        if appServices.loginService.hasLogin {
            initialRoute = Defaults[.showSettingsOnLaunch] ? .settings : nil
        } else {
            initialRoute = .login
        }

        if initialRoute == nil {
            NSApplication.shared.setActivationPolicy(.accessory)
        }

        super.init(initialRoute: initialRoute)

        setupKeyboardShortcuts()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationFailed),
            name: .gitHubAuthenticationFailed,
            object: nil
        )
    }

    private func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .main) { [weak self] in
            guard let self else { return }
            trigger(.main)
        }
    }

    @objc private func handleAuthenticationFailed() {
        trigger(.authenticationFailed)
    }

    override func prepareTransition(for route: AppRoute) -> AppTransition {
        var finalRoute = route
        if route.requiresAuthentication && !appServices.loginService.hasLogin {
            finalRoute = .login
        }
        switch finalRoute {
        case .login:
            return loginTransition(notice: nil)
        case .authenticationFailed:
            return authenticationFailureTransition()
        case .reauthorize:
            return loginTransition(notice: .information(
                "StarLight needs wider access to search your private repositories. Sign in again to grant it."
            ))
        case .settings:
            return settingsTransition()
        case .main:
            return .route(on: mainCoordinator, to: .present)
        case .refresh:
            Task {
                await appServices.starredRepositoriesService.refresh()
                await appServices.personalRepositoriesService.refresh()
            }
            return .none()
        }
    }

    private func loginTransition(notice: LoginNotice?) -> AppTransition {
        let loginCoordinator: LoginCoordinator
        if let existingLoginCoordinator = children.first(where: { $0 is LoginCoordinator }) as? LoginCoordinator {
            loginCoordinator = existingLoginCoordinator
        } else {
            loginCoordinator = LoginCoordinator(appServices: appServices)
        }
        loginCoordinator.delegate = self
        return .route(on: loginCoordinator, to: .login(notice: notice))
    }

    private func settingsTransition() -> AppTransition {
        let settingsCoordinator: SettingsCoordinator
        if let existingSettingsCoordinator = children.first(where: { $0 is SettingsCoordinator }) as? SettingsCoordinator {
            settingsCoordinator = existingSettingsCoordinator
        } else {
            settingsCoordinator = SettingsCoordinator(appServices: appServices)
        }
        settingsCoordinator.delegate = self
        return .route(on: settingsCoordinator, to: .settings)
    }

    private func authenticationFailureTransition() -> AppTransition {
        var transitions: [AppTransition] = [
            .route(on: mainCoordinator, to: .cancel),
        ]
        if let settingsCoordinator = children.first(where: { $0 is SettingsCoordinator }) as? SettingsCoordinator {
            transitions.append(.route(on: settingsCoordinator, to: .dismiss))
        }
        transitions.append(loginTransition(notice: .failure("Your GitHub token is no longer valid. Please log in again.")))
        return .multiple(transitions)
    }
}

extension AppCoordinator: LoginCoordinator.Delegate {
    func loginCoordinatorDidLogin(_ coordinator: LoginCoordinator) {
        trigger(.settings)
    }
}

extension AppCoordinator: SettingsCoordinator.Delegate {
    func settingsCoordinatorDidLogout(_ coordinator: SettingsCoordinator) {
        trigger(.login)
    }

    func settingsCoordinatorDidRequestReauthorization(_ coordinator: SettingsCoordinator) {
        trigger(.reauthorize)
    }
}
