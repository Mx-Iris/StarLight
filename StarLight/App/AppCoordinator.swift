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

enum AppRoute: Routable {
    case login
    case settings
    case main
}

final class AppCoordinator: Coordinator<AppRoute, AppTransition> {
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

        addChild(mainCoordinator)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationFailed),
            name: .repositoriesServiceAuthenticationFailed,
            object: nil
        )
    }

    @objc private func handleAuthenticationFailed() {
        // Skip if already presenting the login screen
        guard !children.contains(where: { $0 is LoginCoordinator }) else { return }

        // Close settings window if open, bypass delegate to avoid double-triggering login
        if let settingsCoordinator = children.first(where: { $0 is SettingsCoordinator }) as? SettingsCoordinator {
            settingsCoordinator.delegate = nil
            settingsCoordinator.windowController.close()
            removeChild(settingsCoordinator)
        }

        // Cancel quick action bar if open
        mainCoordinator.quickActionBarController.cancel()

        let alert = NSAlert()
        alert.messageText = "Authentication Expired"
        alert.informativeText = "Your GitHub token is no longer valid. Please log in again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Log In")
        alert.runModal()

        trigger(.login)
    }

    override func prepareTransition(for route: AppRoute) -> AppTransition {
        switch route {
        case .login:
            let loginCoordinator = LoginCoordinator(appServices: appServices)
            loginCoordinator.delegate = self
            addChild(loginCoordinator)
            return .route(on: loginCoordinator, to: .login)
        case .settings:
            let settingsCoordinator: SettingsCoordinator
            if let child = children.first(where: { $0 is SettingsCoordinator }) as? SettingsCoordinator {
                settingsCoordinator = child
            } else {
                settingsCoordinator = SettingsCoordinator(appServices: appServices)
                addChild(settingsCoordinator)
            }
            settingsCoordinator.delegate = self
            return .route(on: settingsCoordinator, to: .settings)
        case .main:
            return .route(on: mainCoordinator, to: .present)
        }
    }
}

extension AppCoordinator: LoginCoordinator.Delegate {
    func loginCoordinatorDidLogin(_ coordinator: LoginCoordinator) {
        trigger(.settings)
        removeChild(coordinator)
    }
}

extension AppCoordinator: SettingsCoordinator.Delegate {
    func settingsCoordinatorDidLogout(_ coordinator: SettingsCoordinator) {
        trigger(.login)
        removeChild(coordinator)
    }
}
