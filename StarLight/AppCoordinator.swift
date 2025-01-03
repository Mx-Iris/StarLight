//
//  AppCoordinator.swift
//  StarLight
//
//  Created by JH on 2024/12/31.
//

import Foundation
import GitHubModels
import CocoaCoordinator
import StarLightCore

enum AppRoute: Routable {
    case login
    case settings
}

final class AppCoordinator: Coordinator<AppRoute, AppTransition> {
    let appServices: AppServices
    
    init(appServices: AppServices) {
        self.appServices = appServices
        let initialRoute: AppRoute
        if appServices.loginService.hasLogin {
            initialRoute = .settings
        } else {
            initialRoute = .login
        }
        super.init(initialRoute: initialRoute)
    }

    override func prepareTransition(for route: AppRoute) -> AppTransition {
        switch route {
        case .login:
            let loginCoordinator = LoginCoordinator(appServices: appServices)
            loginCoordinator.delegate = self
            addChild(loginCoordinator)
            return .route(on: loginCoordinator, to: .login)
        case .settings:
            let settingsCoordinator = SettingsCoordinator(appServices: appServices)
            addChild(settingsCoordinator)
            return .route(on: settingsCoordinator, to: .main)
        }
    }
}

extension AppCoordinator: LoginCoordinator.Delegate {
    func loginCoordinatorDidLogin(_ coordinator: LoginCoordinator) {
        trigger(.settings)
        removeChild(coordinator)
    }
}
