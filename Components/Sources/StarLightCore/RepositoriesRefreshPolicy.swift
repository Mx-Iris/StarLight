import Foundation

struct RepositoriesRefreshPolicy {
    static func shouldPerformFullRefresh(
        lastFullRefreshDate: Date?,
        currentDate: Date,
        maximumFullRefreshAge: TimeInterval
    ) -> Bool {
        guard let lastFullRefreshDate else { return true }
        return currentDate.timeIntervalSince(lastFullRefreshDate) >= maximumFullRefreshAge
    }

    static func repositoryMembershipChanged(
        cachedRepositoryNames: [String],
        firstPageRepositoryNames: [String],
        remoteRepositoryCount: Int
    ) -> Bool {
        guard cachedRepositoryNames.count == remoteRepositoryCount else { return true }
        return Array(cachedRepositoryNames.prefix(firstPageRepositoryNames.count)) != firstPageRepositoryNames
    }

    static func shouldReplaceRunningRefresh(
        requestedRefreshForcesFullRefresh: Bool,
        runningRefreshPerformsFullRefresh: Bool
    ) -> Bool {
        requestedRefreshForcesFullRefresh && !runningRefreshPerformsFullRefresh
    }
}
