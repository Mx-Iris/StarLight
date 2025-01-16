//
//  StatusItemController.swift
//  StarLight
//
//  Created by JH on 2025/1/5.
//

import AppKit
import SFSymbol
import MenuBuilder
import StatusItemController
import CocoaCoordinator

final class AppStatusItemController: StatusItemController {
    unowned let router: any Router<AppRoute>

    init(router: any Router<AppRoute>) {
        self.router = router
        super.init(image: .symbol(systemName: .starFill))
    }

    override func buildMenu() -> NSMenu {
        NSMenu {
            MenuItem("Show Main Window")
                .onSelect { [weak self] in
                    guard let self else { return }
                    router.trigger(.main)
                }
            SeparatorItem()
            MenuItem("Settings...")
                .onSelect { [weak self] in
                    guard let self else { return }
                    router.trigger(.settings)
                }
            SeparatorItem()
            MenuItem("Quit")
                .onSelect(target: self, action: #selector(quit))
        }
    }

    override func leftClickAction() {
        router.trigger(.main)
    }

    override func rightClickAction() {
        openMenu()
    }
}
