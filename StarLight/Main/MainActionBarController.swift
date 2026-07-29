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
import StarLightCore

@MainActor
final class MainActionBarController: NSObject {
    let actionBar = QuickActionBar()

    let appServices: AppServices

    private var starredRepositoriesSubscription: AnyCancellable?
    private var personalRepositoriesSubscription: AnyCancellable?

    private enum PresentationState: Equatable {
        case idle
        case preparing(requestIdentifier: UInt)
        case presented
        case dismissing
    }

    private var presentationState: PresentationState = .idle
    private var presentationPreparationTask: Task<Void, Never>?
    private var nextPresentationRequestIdentifier: UInt = 0
    private var cachedSearchIndex: CachedSearchIndex?

    init(appServices: AppServices) {
        self.appServices = appServices
        super.init()
        actionBar.contentSource = self
        actionBar.rowHeight = 60
        observeRepositoriesChanges()
    }

    /// The index the quick action bar searches: the user's own and organization repositories ahead
    /// of their starred ones, deduplicated, with private repositories filtered out unless the user
    /// asked for them, and every searchable field pre-split into words.
    ///
    /// Building it walks the whole collection, which is far too slow to redo on every keystroke, so
    /// it is cached until the repositories change underneath it — see `observeRepositoriesChanges`.
    /// The private-repository setting is checked here rather than observed, since it is the other
    /// input that changes what belongs in the index.
    private func searchIndex() async -> RepositorySearchIndex {
        let includingPrivateRepositories = Defaults[.includePrivateRepositories]

        if let cachedSearchIndex, cachedSearchIndex.includedPrivateRepositories == includingPrivateRepositories {
            return cachedSearchIndex.index
        }

        let personalRepositories = await appServices.personalRepositoriesService.cachedRepositories
        let starredRepositories = await appServices.starredRepositoriesService.cachedRepositories

        let repositories = RepositorySearchCatalog.merged(
            personalRepositories: personalRepositories,
            starredRepositories: starredRepositories,
            includingPrivateRepositories: includingPrivateRepositories
        )

        // Splitting thousands of repositories into words would visibly stall the panel if it ran on
        // the main actor.
        let index = await Task.detached { RepositorySearchIndex(repositories: repositories) }.value

        cachedSearchIndex = CachedSearchIndex(
            index: index,
            includedPrivateRepositories: includingPrivateRepositories
        )
        return index
    }

    private struct CachedSearchIndex {
        let index: RepositorySearchIndex
        let includedPrivateRepositories: Bool
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
            // Presenting the panel is also where the index gets built, so the first keystroke after
            // it opens searches an index that is already warm.
            let hasCachedRepositories = await !searchIndex().isEmpty
            guard !Task.isCancelled else { return }

            let placeholderText = hasCachedRepositories ? "Search Repositories" : "Loading repositories..."
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
            starredRepositoriesSubscription = await appServices.starredRepositoriesService.$repositoriesChangeIdentifier
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.invalidateSearchIndex()
                }

            personalRepositoriesSubscription = await appServices.personalRepositoriesService.$repositoriesChangeIdentifier
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.invalidateSearchIndex()
                }
        }
    }

    /// Drops the cached index when a collection finishes refreshing behind the panel, and keeps an
    /// open panel in sync with what the next search will find.
    private func invalidateSearchIndex() {
        cachedSearchIndex = nil

        guard actionBar.isPresenting else { return }

        Task { [weak self] in
            guard let self else { return }
            let searchTerm = await MainActor.run { self.actionBar.currentSearchText ?? "" }
            guard !searchTerm.isEmpty else { return }

            let matchingRepositories = await searchIndex().search(matching: searchTerm)

            await MainActor.run {
                self.actionBar.provideResultIdentifiers(matchingRepositories)
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
            let matchingRepositories = await searchIndex().search(matching: task.searchTerm)
            await MainActor.run {
                task.complete(with: matchingRepositories)
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
