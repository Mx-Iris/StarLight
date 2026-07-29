import Foundation
import Testing
@testable import StarLightCore

struct StarredRepositoriesRefreshPolicyTests {
    @Test
    func requiresFullRefreshWithoutPreviousRefreshDate() {
        #expect(StarredRepositoriesRefreshPolicy.shouldPerformFullRefresh(
            lastFullRefreshDate: nil,
            currentDate: Date(timeIntervalSince1970: 1_000),
            maximumFullRefreshAge: 100
        ))
    }

    @Test
    func requiresFullRefreshWhenMaximumAgeIsReached() {
        #expect(StarredRepositoriesRefreshPolicy.shouldPerformFullRefresh(
            lastFullRefreshDate: Date(timeIntervalSince1970: 900),
            currentDate: Date(timeIntervalSince1970: 1_000),
            maximumFullRefreshAge: 100
        ))
    }

    @Test
    func keepsLightweightRefreshWithinMaximumAge() {
        #expect(!StarredRepositoriesRefreshPolicy.shouldPerformFullRefresh(
            lastFullRefreshDate: Date(timeIntervalSince1970: 901),
            currentDate: Date(timeIntervalSince1970: 1_000),
            maximumFullRefreshAge: 100
        ))
    }

    @Test
    func detectsRepositoryCountChanges() {
        #expect(StarredRepositoriesRefreshPolicy.repositoryMembershipChanged(
            cachedRepositoryNames: ["owner/first", "owner/second"],
            firstPageRepositoryNames: ["owner/first"],
            remoteRepositoryCount: 1
        ))
    }

    @Test
    func detectsNewestRepositoryChanges() {
        #expect(StarredRepositoriesRefreshPolicy.repositoryMembershipChanged(
            cachedRepositoryNames: ["owner/first", "owner/second"],
            firstPageRepositoryNames: ["owner/new"],
            remoteRepositoryCount: 2
        ))
    }

    @Test
    func acceptsMatchingRepositoryMembership() {
        #expect(!StarredRepositoriesRefreshPolicy.repositoryMembershipChanged(
            cachedRepositoryNames: ["owner/first", "owner/second"],
            firstPageRepositoryNames: ["owner/first"],
            remoteRepositoryCount: 2
        ))
    }

    @Test
    func replacesAutomaticRefreshWithManualFullRefresh() {
        #expect(StarredRepositoriesRefreshPolicy.shouldReplaceRunningRefresh(
            requestedRefreshForcesFullRefresh: true,
            runningRefreshPerformsFullRefresh: false
        ))
    }

    @Test
    func reusesRunningFullRefreshForManualRefresh() {
        #expect(!StarredRepositoriesRefreshPolicy.shouldReplaceRunningRefresh(
            requestedRefreshForcesFullRefresh: true,
            runningRefreshPerformsFullRefresh: true
        ))
    }

    @Test
    func reusesRunningAutomaticRefreshForAnotherAutomaticRefresh() {
        #expect(!StarredRepositoriesRefreshPolicy.shouldReplaceRunningRefresh(
            requestedRefreshForcesFullRefresh: false,
            runningRefreshPerformsFullRefresh: false
        ))
    }
}
