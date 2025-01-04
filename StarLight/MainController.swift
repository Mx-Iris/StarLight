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

final class MainController: NSObject {
    let quickActionBar = DSFQuickActionBar()

    let appServices: AppServices

    init(appServices: AppServices) {
        self.appServices = appServices
        super.init()
        quickActionBar.contentSource = self
        quickActionBar.rowHeight = 48
        setupKeyboardShortcuts()
    }
    func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .main) { [weak self] in
            guard let self else { return }
            quickActionBar.present()
        }
    }
}

extension MainController: DSFQuickActionBarContentSource {
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, viewForItem item: AnyHashable, searchTerm: String) -> NSView? {
        guard let repository = item as? Repository else { return nil }
        return NSHostingView(rootView: QuickActionBarCell(repository: repository))
    }

    func quickActionBar(_ quickActionBar: DSFQuickActionBar, itemsForSearchTermTask task: DSFQuickActionBar.SearchTask) {
        if appServices.store.repositories.isEmpty {
            Task {
                do {
                    try await appServices.store.fetchRepositories()
                    await MainActor.run {
                        task.complete(with: appServices.store.repositories.filter { $0.fullname.contains(task.searchTerm) })
                    }
                } catch {
                    print(error)
                }
            }
        } else {
            task.complete(with: appServices.store.repositories.filter { $0.fullname.contains(task.searchTerm) })
        }
    }

    func quickActionBar(_ quickActionBar: DSFQuickActionBar, didActivateItem item: AnyHashable) {
        guard let repository = item as? Repository else { return }
        NSWorkspace.shared.open(repository.htmlURL)
    }
}

struct QuickActionBarCell: View {
    var repository: Repository

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(repository.fullname)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Text(repository.description ?? "")
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
    }
}

#Preview {
    QuickActionBarCell(repository: .testModel)
        .frame(width: 500, height: 50)
}
