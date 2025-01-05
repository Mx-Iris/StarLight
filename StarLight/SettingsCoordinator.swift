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
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(_:)), name: NSWindow.willCloseNotification, object: windowController.window)
    }

    override func prepareTransition(for route: SettingsRoute) -> SettingsTransition {
        switch route {
        case .settings:
            let settingsViewController = SettingsViewController(viewModel: .init(appServices: appServices, router: self))
            return .show(settingsViewController)
        case .logout:
            return .close()
        }
    }
}

extension SettingsCoordinator {
    @objc func windowWillClose(_ notification: Notification) {
        removeFromParent()
    }
}
