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
    case main
    case logout
}

typealias SettingsTransition = SceneTransition<SettingsWindowController, SettingsViewController>

final class SettingsCoordinator: SceneCoordinator<SettingsRoute, SettingsTransition> {
    let appServices: AppServices

    init(appServices: AppServices) {
        self.appServices = appServices
        super.init(windowController: .init(), initialRoute: nil)
    }
}

