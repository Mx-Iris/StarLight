//
//  QuickActionBarCoordinator.swift
//  StarLight
//
//  Created by JH on 2025/1/3.
//

import AppKit
import SwiftUI
import GitHubModels
import StarLightCore
import StarLightResources
import CocoaCoordinator
import DSFQuickActionBar
import KeyboardShortcuts
import SDWebImageSwiftUI
import Defaults

enum MainAction: Int, RawRepresentable, Defaults.Serializable {
    case openURL
    case copyURL
    case openAndCopyURL
}

enum MainRoute: Routable {
    case present
    case cancel
}

final class MainCoordinator: Coordinator<MainRoute, AppTransition> {
    let appServices: AppServices

    let quickActionBarController: MainActionBarController

    init(appServices: AppServices) {
        self.appServices = appServices
        self.quickActionBarController = .init(appServices: appServices)
        super.init(initialRoute: nil)
        setupKeyboardShortcuts()
    }

    override func prepareTransition(for route: MainRoute) -> AppTransition {
        switch route {
        case .present:
            quickActionBarController.present()
            return .none()
        case .cancel:
            quickActionBarController.cancel()
            return .none()
        }
    }

    func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .main) { [weak self] in
            guard let self, appServices.loginService.hasLogin else { return }
            trigger(.present)
        }
    }
}
