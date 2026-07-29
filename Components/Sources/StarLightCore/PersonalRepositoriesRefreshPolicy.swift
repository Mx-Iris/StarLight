import Foundation

struct PersonalRepositoriesRefreshPolicy {
    /// Unlike the starred collection, this one has no cheap way to probe for changes: the endpoints
    /// it reads are not returned as paginated responses carrying a last-page number, so there is no
    /// remote count to compare against, and organization repositories are not covered by probing
    /// `/user/repos` at all. Every refresh therefore walks all pages, and the automatic timer is
    /// throttled to a minimum interval instead. A manual refresh skips this check entirely.
    static func shouldRefresh(
        lastFullRefreshDate: Date?,
        currentDate: Date,
        minimumFullRefreshInterval: TimeInterval
    ) -> Bool {
        guard let lastFullRefreshDate else { return true }
        return currentDate.timeIntervalSince(lastFullRefreshDate) >= minimumFullRefreshInterval
    }
}
