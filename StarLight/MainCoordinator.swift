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
import StarLightCore
import SDWebImageSwiftUI
import StarLightResources

enum MainRoute: Routable {
    case present
    case cancel
}

final class MainCoordinator: Coordinator<MainRoute, AppTransition> {
    let appServices: AppServices

    let quickActionBarController: QuickActionBarController

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

final class QuickActionBarController: NSObject {
    let quickActionBar = DSFQuickActionBar()

    let appServices: AppServices

    init(appServices: AppServices) {
        self.appServices = appServices
        super.init()
        quickActionBar.contentSource = self
        quickActionBar.rowHeight = 48
    }

    func present() {
        quickActionBar.cancel()
        quickActionBar.present(placeholderText: "Search Starred Repositories")
    }

    func cancel() {
        quickActionBar.cancel()
    }
}

extension QuickActionBarController: DSFQuickActionBarContentSource {
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, viewForItem item: AnyHashable, searchTerm: String) -> NSView? {
        guard let repository = item as? Repository else { return nil }
        return NSHostingView(rootView: StarLightCell(repository: repository))
    }

    func quickActionBar(_ quickActionBar: DSFQuickActionBar, itemsForSearchTermTask task: DSFQuickActionBar.SearchTask) {
        Task {
            do {
                let repositories = try await appServices.store.repositories
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
        NSWorkspace.shared.open(repository.htmlURL)
    }

    func quickActionBar(_ quickActionBar: DSFQuickActionBar, canSelectItem item: AnyHashable) -> Bool {
        true
    }
}

struct StarLightCell: View {
    var repository: Repository

    var body: some View {
        HStack(spacing: 10) {
            WebImage(
                url: repository.owner?.avatarURL,
                content: { image in
                    image
                        .resizable()
                        .frame(maxWidth: 30, maxHeight: 30)
                        .cornerRadius(5)
                },
                placeholder: {
                    ProgressView()
                }
            )
            .frame(maxWidth: 30, maxHeight: 30)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(repository.fullname)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                if Settings.showRepositoryDescription {
                    HStack {
                        Text(repository.description ?? "No description")
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.secondary)
                            .font(.callout)
                        Spacer()
                    }
                }
                HStack(spacing: 15) {
                    if let programmingLanguage = repository.programmingLanguage {
                        HStack(spacing: 5) {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundColor(Color(nsColor: programmingLanguage.color?.nsColor ?? .white))
                            Text(programmingLanguage.rawValue)
                                .font(.callout)
                        }
                    }
//                    if let license = repository.license {
//                        Assets.Octicons.law16.swiftUIImage
//                            .foregroundColor(.secondary)
//                        Text(license.name ?? "No license")
//                            .foregroundColor(.secondary)
//                    }

                    HStack(spacing: 5) {
                        Assets.Octicons.star16.swiftUIImage
                            .foregroundColor(.secondary)
                        Text(repository.stargazersCount.string)
                            .foregroundColor(.secondary)
                            .font(.callout)
                    }
                    HStack(spacing: 5) {
                        Assets.Octicons.repoForked16.swiftUIImage
                            .foregroundColor(.secondary)
                        Text(repository.forksCount.string)
                            .foregroundColor(.secondary)
                            .font(.callout)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
    }
}

#Preview {
    StarLightCell(repository: .testModel)
}
