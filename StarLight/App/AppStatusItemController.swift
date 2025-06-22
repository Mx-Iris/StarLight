//
//  StatusItemController.swift
//  StarLight
//
//  Created by JH on 2025/1/5.
//

import AppKit
import Combine
import SFSymbol
import MenuBuilder
import StatusItemController
import CocoaCoordinator

final class AppStatusItemController: StatusItemController {
    private let appServices: AppServices
    private unowned let router: any Router<AppRoute>
    private var repositoriesServiceToken: AnyCancellable?

    private lazy var progressView: NSProgressIndicator = {
        let progressView = NSProgressIndicator()
        progressView.isIndeterminate = true
        progressView.style = .spinning
        progressView.controlSize = .small
        return progressView
    }()

    init(appServices: AppServices, router: any Router<AppRoute>) {
        self.appServices = appServices
        self.router = router
        super.init(image: .symbol(systemName: .starFill))
        Task {
            self.repositoriesServiceToken = await appServices.repositoriesService.$state
                .receive(on: RunLoop.main)
                .sink { [weak self] state in
                    guard let self, let button = statusItem.button else { return }
                    switch state {
                    case .idle:
                        progressView.removeFromSuperview()
                        progressView.stopAnimation(nil)
                        button.image = .symbol(systemName: .starFill)
                    default:
                        progressView.sizeToFit()
                        button.frame = .init(origin: .zero, size: .init(width: 110, height: 22))
                        button.addSubview(progressView)
                        NSLayoutConstraint.activate([
                            progressView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                            progressView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                        ])
                        progressView.startAnimation(nil)
                        button.image = nil
                    }
                }
        }
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
            MenuItem("Refresh")
                .onSelect { [weak self] in
                    guard let self else { return }
                    Task {
                        await self.appServices.repositoriesService.refresh()
                    }
                }
            SeparatorItem()
            MenuItem("Quit")
                .onSelect(target: self, action: #selector(quit))
        }
    }

    override func leftClickAction() {
        openMenu()
    }
}
