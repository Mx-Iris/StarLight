//
//  MainCoordinator.swift
//  StarLight
//
//  Created by JH on 2025/1/1.
//

import AppKit
import UIFoundation
import CocoaCoordinator

enum SettingsRoute: Routable {
    case settings
    case logout
}

typealias SettingsTransition = SceneTransition<SettingsWindowController, SettingsViewController>

final class SettingsCoordinator: SceneCoordinator<SettingsRoute, SettingsTransition> {
    let appServices: AppServices

    init(appServices: AppServices) {
        self.appServices = appServices
        super.init(windowController: .init(), initialRoute: nil)
    }
    override func prepareTransition(for route: SettingsRoute) -> SettingsTransition {
        switch route {
        case .settings:
            let settingsViewController = SettingsViewController()
            return .show(settingsViewController)
        case .logout:
            return .close()
        }
    }
}

