//
//  StatusItemController.swift
//  StarLight
//
//  Created by JH on 2025/1/5.
//

import AppKit
import Combine
import SFSymbols
import MenuBuilder
import StatusItemController
import CocoaCoordinator

final class AppStatusItemController: StatusItemController {
    private let appServices: AppServices
    private unowned let router: any Router<AppRoute>
    private var repositoriesStateSubscription: AnyCancellable?

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
            let starredStatePublisher = await appServices.starredRepositoriesService.$state
            let personalStatePublisher = await appServices.personalRepositoriesService.$state

            // The spinner stands for "StarLight is busy", so it has to cover both collections.
            self.repositoriesStateSubscription = Publishers
                .CombineLatest(starredStatePublisher, personalStatePublisher)
                .map { starredState, personalState in
                    starredState == .idle && personalState == .idle
                }
                .removeDuplicates()
                .receive(on: RunLoop.main)
                .sink { [weak self] isIdle in
                    self?.updateStatusItemButton(isIdle: isIdle)
                }
        }
    }

    private func updateStatusItemButton(isIdle: Bool) {
        guard let button = statusItem.button else { return }

        if isIdle {
            progressView.removeFromSuperview()
            progressView.stopAnimation(nil)
            button.image = .symbol(systemName: .starFill)
        } else {
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
                    router.trigger(.refresh)
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
