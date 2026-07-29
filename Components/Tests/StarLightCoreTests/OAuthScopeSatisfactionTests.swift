import Foundation
import Testing
import GitHubNetworking
@testable import StarLightCore

struct OAuthScopeSatisfactionTests {
    @Test
    func treatsMissingScopeStringAsNothingGranted() {
        #expect(!OAuthScopeSatisfaction.grantedScopeString(nil, satisfies: [.readUser]))
    }

    @Test
    func acceptsExactlyMatchingScopes() {
        #expect(OAuthScopeSatisfaction.grantedScopeString(
            "read:user,public_repo",
            satisfies: RepositoryAccessLevel.publicRepositoriesOnly.scopes
        ))
    }

    @Test
    func acceptsSpaceSeparatedScopes() {
        #expect(OAuthScopeSatisfaction.grantedScopeString(
            "read:user public_repo",
            satisfies: RepositoryAccessLevel.publicRepositoriesOnly.scopes
        ))
    }

    @Test
    func rejectsPublicOnlyTokenForPrivateAccess() {
        #expect(!OAuthScopeSatisfaction.grantedScopeString(
            "read:user,public_repo",
            satisfies: RepositoryAccessLevel.includingPrivateRepositories.scopes
        ))
    }

    @Test
    func acceptsPrivateTokenForPublicAccess() {
        #expect(OAuthScopeSatisfaction.grantedScopeString(
            "read:user,repo,read:org",
            satisfies: RepositoryAccessLevel.publicRepositoriesOnly.scopes
        ))
    }

    @Test
    func expandsRepositoryScopeToPublicRepositoryScope() {
        #expect(OAuthScopeSatisfaction.expandedScopes(from: [OAuthScope.repo]).contains(.publicRepo))
    }

    @Test
    func expandsOrganizationAdministrationScopeTransitively() {
        // admin:org reaches read:org only by way of write:org.
        #expect(OAuthScopeSatisfaction.expandedScopes(from: [OAuthScope.adminOrg]).contains(.readOrg))
    }

    @Test
    func expandsUserScopeToReadUserScope() {
        #expect(OAuthScopeSatisfaction.grantedScopeString("user,repo", satisfies: [.readUser, .publicRepo]))
    }

    @Test
    func ignoresUnrecognizedScopes() {
        #expect(OAuthScopeSatisfaction.grantedScopeString(
            "read:user,public_repo,some_future_scope",
            satisfies: RepositoryAccessLevel.publicRepositoriesOnly.scopes
        ))
    }
}
