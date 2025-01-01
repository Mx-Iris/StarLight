//
//  MainCoordinator.swift
//  StarLight
//
//  Created by JH on 2025/1/1.
//

import AppKit
import UIFoundation
import CocoaCoordinator

enum MainRoute: Routable {
    case main
    case logout
}

typealias MainTransition = SceneTransition<MainWindowController, MainViewController>

final class MainCoordinator: SceneCoordinator<MainRoute, MainTransition> {
    let appServices: AppServices
    
    init(appServices: AppServices) {
        self.appServices = appServices
        super.init(windowController: .init(), initialRoute: nil)
    }
}

final class MainWindow: NSWindow {}

final class MainWindowController: XiblessWindowController<MainWindow> {
    
}

final class MainView: XiblessView {}

final class MainViewController: XiblessViewController<MainView> {}
