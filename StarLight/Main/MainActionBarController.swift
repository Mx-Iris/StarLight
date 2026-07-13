//
//  MainActionBarController.swift
//  StarLight
//
//  Created by JH on 2025/1/22.
//

import AppKit
import SwiftUI
import Combine
import GitHubModels
import UIFoundation
import Defaults

@MainActor
final class MainActionBarController: NSObject {
    let actionBar = QuickActionBar()

    let appServices: AppServices

    private var repositoriesSubscription: AnyCancellable?

    private enum PresentationState: Equatable {
        case idle
        case preparing(requestIdentifier: UInt)
        case presented
        case dismissing
    }

    private var presentationState: PresentationState = .idle
    private var presentationPreparationTask: Task<Void, Never>?
    private var nextPresentationRequestIdentifier: UInt = 0

    init(appServices: AppServices) {
        self.appServices = appServices
        super.init()
        actionBar.contentSource = self
        actionBar.rowHeight = 60
        observeRepositoriesChanges()
    }

    /// Matches a repository against a search term by checking multiple fields:
    /// name, fullname (owner/repo), description, topics, and language.
    /// Supports multi-word queries where each word must match at least one field.
    private func repositoryMatchesSearchTerm(_ repository: Repository, searchTerm: String) -> Bool {
        let words = searchTerm.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return false }
        return words.allSatisfy { word in
            repository.name.localizedCaseInsensitiveContains(word)
                || repository.fullname.localizedCaseInsensitiveContains(word)
                || (repository.description?.localizedCaseInsensitiveContains(word) ?? false)
                || (repository.language?.localizedCaseInsensitiveContains(word) ?? false)
                || repository.topics.contains(where: { $0.localizedCaseInsensitiveContains(word) })
        }
    }

    func present() {
        switch presentationState {
        case .idle:
            preparePresentation()
        case .preparing:
            cancel()
        case .presented:
            if actionBar.resumePresentation() {
                return
            }

            presentationState = .dismissing
            actionBar.cancel()
        case .dismissing:
            guard actionBar.resumePresentation() else { return }
            presentationState = .presented
        }
    }

    func cancel() {
        presentationPreparationTask?.cancel()
        presentationPreparationTask = nil

        if actionBar.isPresenting {
            presentationState = .dismissing
            actionBar.cancel()
        } else {
            presentationState = .idle
        }
    }

    private func preparePresentation() {
        nextPresentationRequestIdentifier &+= 1
        let presentationRequestIdentifier = nextPresentationRequestIdentifier
        presentationState = .preparing(requestIdentifier: presentationRequestIdentifier)

        presentationPreparationTask = Task { [weak self] in
            guard let self else { return }
            let hasCachedRepositories = await !appServices.repositoriesService.cachedRepositories.isEmpty
            guard !Task.isCancelled else { return }

            let placeholderText = hasCachedRepositories ? "Search Starred Repositories" : "Loading repositories..."
            guard presentationState == .preparing(requestIdentifier: presentationRequestIdentifier) else { return }

            presentationPreparationTask = nil
            presentationState = .presented
            actionBar.present(
                placeholderText: placeholderText,
                width: Defaults[.windowWidth],
                height: Defaults[.windowHeight]
            ) { [weak self] in
                self?.handleActionBarDidClose()
            }

            if !actionBar.isPresenting {
                presentationState = .idle
            }
        }
    }

    private func handleActionBarDidClose() {
        switch presentationState {
        case .presented, .dismissing:
            presentationState = .idle
        case .idle, .preparing:
            break
        }
    }

    private func observeRepositoriesChanges() {
        Task {
            repositoriesSubscription = await appServices.repositoriesService.$repositoriesChangeIdentifier
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self, actionBar.isPresenting else { return }
                    Task {
                        let searchTerm = await MainActor.run { self.actionBar.currentSearchText ?? "" }
                        guard !searchTerm.isEmpty else { return }
                        let repos = await self.appServices.repositoriesService.cachedRepositories
                        let filtered = repos.filter {
                            self.repositoryMatchesSearchTerm($0, searchTerm: searchTerm)
                        }
                        await MainActor.run {
                            self.actionBar.provideResultIdentifiers(filtered)
                        }
                    }
                }
        }
    }
}

extension MainActionBarController: @MainActor QuickActionBarContentSource {
    func quickActionBar(_ quickActionBar: QuickActionBar, viewForItem item: AnyHashable, searchTerm: String) -> NSView? {
        guard let repository = item as? Repository else { return nil }
        return NSHostingView(rootView: MainActionBarCellView(repository: repository))
    }

    func quickActionBar(_ quickActionBar: QuickActionBar, itemsForSearchTermTask task: QuickActionBar.SearchTask) {
        guard !task.searchTerm.isEmpty else {
            task.complete(with: [])
            return
        }
        Task {
            let repositories = await appServices.repositoriesService.cachedRepositories
            let filtered = repositories.filter {
                self.repositoryMatchesSearchTerm($0, searchTerm: task.searchTerm)
            }
            await MainActor.run {
                task.complete(with: filtered)
            }
        }
    }

    func quickActionBar(_ quickActionBar: QuickActionBar, didActivateItem item: AnyHashable) {
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

    func quickActionBar(_ quickActionBar: QuickActionBar, canSelectItem item: AnyHashable) -> Bool {
        true
    }
}
