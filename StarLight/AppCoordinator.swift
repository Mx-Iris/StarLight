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
            initialRoute = Settings.showSettingsOnLaunch ? .settings : nil
        } else {
            initialRoute = .login
        }
        super.init(initialRoute: initialRoute)
        
    
        addChild(mainCoordinator)
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
