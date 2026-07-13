import Foundation
import Testing
@testable import StarLightCore

struct RepositoriesRefreshPolicyTests {
    @Test
    func requiresFullRefreshWithoutPreviousRefreshDate() {
        #expect(RepositoriesRefreshPolicy.shouldPerformFullRefresh(
            lastFullRefreshDate: nil,
            currentDate: Date(timeIntervalSince1970: 1_000),
            maximumFullRefreshAge: 100
        ))
    }

    @Test
    func requiresFullRefreshWhenMaximumAgeIsReached() {
        #expect(RepositoriesRefreshPolicy.shouldPerformFullRefresh(
            lastFullRefreshDate: Date(timeIntervalSince1970: 900),
            currentDate: Date(timeIntervalSince1970: 1_000),
            maximumFullRefreshAge: 100
        ))
    }

    @Test
    func keepsLightweightRefreshWithinMaximumAge() {
        #expect(!RepositoriesRefreshPolicy.shouldPerformFullRefresh(
            lastFullRefreshDate: Date(timeIntervalSince1970: 901),
            currentDate: Date(timeIntervalSince1970: 1_000),
            maximumFullRefreshAge: 100
        ))
    }

    @Test
    func detectsRepositoryCountChanges() {
        #expect(RepositoriesRefreshPolicy.repositoryMembershipChanged(
            cachedRepositoryNames: ["owner/first", "owner/second"],
            firstPageRepositoryNames: ["owner/first"],
            remoteRepositoryCount: 1
        ))
    }

    @Test
    func detectsNewestRepositoryChanges() {
        #expect(RepositoriesRefreshPolicy.repositoryMembershipChanged(
            cachedRepositoryNames: ["owner/first", "owner/second"],
            firstPageRepositoryNames: ["owner/new"],
            remoteRepositoryCount: 2
        ))
    }

    @Test
    func acceptsMatchingRepositoryMembership() {
        #expect(!RepositoriesRefreshPolicy.repositoryMembershipChanged(
            cachedRepositoryNames: ["owner/first", "owner/second"],
            firstPageRepositoryNames: ["owner/first"],
            remoteRepositoryCount: 2
        ))
    }

    @Test
    func replacesAutomaticRefreshWithManualFullRefresh() {
        #expect(RepositoriesRefreshPolicy.shouldReplaceRunningRefresh(
            requestedRefreshForcesFullRefresh: true,
            runningRefreshPerformsFullRefresh: false
        ))
    }

    @Test
    func reusesRunningFullRefreshForManualRefresh() {
        #expect(!RepositoriesRefreshPolicy.shouldReplaceRunningRefresh(
            requestedRefreshForcesFullRefresh: true,
            runningRefreshPerformsFullRefresh: true
        ))
    }

    @Test
    func reusesRunningAutomaticRefreshForAnotherAutomaticRefresh() {
        #expect(!RepositoriesRefreshPolicy.shouldReplaceRunningRefresh(
            requestedRefreshForcesFullRefresh: false,
            runningRefreshPerformsFullRefresh: false
        ))
    }
}
