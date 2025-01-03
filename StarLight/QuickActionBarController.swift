//
//  QuickActionBarCoordinator.swift
//  StarLight
//
//  Created by JH on 2025/1/3.
//

import AppKit
import SwiftUI
import CocoaCoordinator
import DSFQuickActionBar
import GitHubModels
import KeyboardShortcuts

enum MainRoute: Routable {
    case present
    case cancel
}

final class MainCoordinator: Coordinator<MainRoute, AppTransition> {
    let appServices: AppServices

    var mainController: MainController?

    init(appServices: AppServices) {
        self.appServices = appServices
        super.init(initialRoute: nil)
        mainController = .init(viewModel: .init(appServices: appServices, router: self))
    }

    override func prepareTransition(for route: MainRoute) -> AppTransition {
        switch route {
        case .present:
            mainController?.quickActionBar.present()
            return .none()
        case .cancel:
            mainController?.quickActionBar.cancel()
            return .none()
        }
    }
}

class MainViewModel: ViewModel<MainRoute> {
    
    var repositories: [Repository] {
        appServices.store.repositories
    }
    
    override init(appServices: AppServices, router: any Router<MainRoute>) {
        super.init(appServices: appServices, router: router)

        setupKeyboardShortcuts()
    }

    func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .main) { [weak self] in
            guard let self else { return }
            router.trigger(.present)
        }
    }
}

final class MainController: NSObject {
    let quickActionBar = DSFQuickActionBar()

    let viewModel: MainViewModel

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
}

extension MainController: DSFQuickActionBarContentSource {
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, viewForItem item: AnyHashable, searchTerm: String) -> NSView? {
        guard let repository = item as? Repository else { return nil }
        return NSHostingView(rootView: QuickActionBarCell(repository: repository))
    }

    func quickActionBar(_ quickActionBar: DSFQuickActionBar, itemsForSearchTermTask task: DSFQuickActionBar.SearchTask) {
        task.complete(with: viewModel.repositories.filter { $0.fullname.contains(task.searchTerm) })
    }

    func quickActionBar(_ quickActionBar: DSFQuickActionBar, didActivateItem item: AnyHashable) {
        guard let repository = item as? Repository else { return }
        NSWorkspace.shared.open(repository.htmlURL)
    }
}

struct QuickActionBarCell: View {
    var repository: Repository

    var body: some View {
        HStack {
            Text(repository.fullname)
            Text(repository.stargazersCount.string)
        }
    }
}

#Preview {
    QuickActionBarCell(repository: .testModel)
        .frame(width: 500, height: 50)
}
