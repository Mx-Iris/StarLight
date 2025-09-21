//
//  MainActionBarController.swift
//  StarLight
//
//  Created by JH on 2025/1/22.
//

import AppKit
import SwiftUI
import GitHubModels
import DSFQuickActionBar
import Defaults

final class MainActionBarController: NSObject {
    let actionBar = DSFQuickActionBar()

    let appServices: AppServices

    init(appServices: AppServices) {
        self.appServices = appServices
        super.init()
        actionBar.contentSource = self
        actionBar.rowHeight = 60
    }

    func present() {
        actionBar.cancel()
        actionBar.present(placeholderText: "Search Starred Repositories", width: Defaults[.windowWidth], height: Defaults[.windowHeight])
    }

    func cancel() {
        actionBar.cancel()
    }
}

extension MainActionBarController: DSFQuickActionBarContentSource {
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, viewForItem item: AnyHashable, searchTerm: String) -> NSView? {
        guard let repository = item as? Repository else { return nil }
        return NSHostingView(rootView: MainActionBarCellView(repository: repository))
    }

    func quickActionBar(_ quickActionBar: DSFQuickActionBar, itemsForSearchTermTask task: DSFQuickActionBar.SearchTask) {
        Task.detached { [self] in
            do {
                let repositories = try await appServices.repositoriesService.repositories
                await MainActor.run {
                    task.complete(with: repositories.filter { $0.name.localizedCaseInsensitiveContains(task.searchTerm) })
                }
            } catch {
                print(error)
            }
        }
    }

    func quickActionBar(_ quickActionBar: DSFQuickActionBar, didActivateItem item: AnyHashable) {
        guard let repository = item as? Repository else { return }
        switch Defaults[.mainAction] {
        case .openURL:
            openURL(for: repository)
        case .copyURL:
            copyURL(for: repository)
        case .openAndCopyURL:
            openURL(for: repository)
            copyURL(for: repository)
        }
    }

    func copyURL(for repository: Repository) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(repository.htmlURL.absoluteString, forType: .string)
    }

    func openURL(for repository: Repository) {
        NSWorkspace.shared.open(repository.htmlURL)
    }

    func quickActionBar(_ quickActionBar: DSFQuickActionBar, canSelectItem item: AnyHashable) -> Bool {
        true
    }
}
