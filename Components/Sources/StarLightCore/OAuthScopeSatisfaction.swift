import Foundation
import GitHubNetworking

/// GitHub's OAuth scopes form a hierarchy: granting a broad scope implicitly grants the narrower
/// ones beneath it, while the `scope` string returned alongside an access token lists only what was
/// literally requested. Comparing those strings directly would ask someone who already granted
/// `repo` to authorize all over again just to obtain `public_repo`.
///
/// See https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps
enum OAuthScopeSatisfaction {
    private static let implicitlyGrantedScopes: [OAuthScope: [OAuthScope]] = [
        .repo: [.repoStatus, .repoDeployment, .publicRepo, .repoInvite, .securityEvents],
        .writePackages: [.readPackages],
        .adminOrg: [.writeOrg, .manageRunnersOrg],
        .writeOrg: [.readOrg],
        .adminPublicKey: [.writePublicKey],
        .writePublicKey: [.readPublicKey],
        .adminRepoHook: [.writeRepoHook],
        .writeRepoHook: [.readRepoHook],
        .user: [.readUser, .userEmail, .userFollow],
        .writeDiscussion: [.readDiscussion],
        .adminEnterprise: [.manageRunnersEnterprise, .manageBillingEnterprise, .readEnterprise],
        .adminGpgKey: [.writeGpgKey],
        .writeGpgKey: [.readGpgKey],
        .project: [.readProject],
        .adminSSHSigningKey: [.writeSSHSigningKey],
        .writeSSHSigningKey: [.readSSHSigningKey],
        .auditLog: [.readAuditLog],
        .codespace: [.codespaceSecrets],
    ]

    /// Expands the given scopes into every scope they confer, following the hierarchy transitively
    /// so that `admin:org` reaches `read:org` through `write:org`.
    static func expandedScopes(from grantedScopes: some Sequence<OAuthScope>) -> Set<OAuthScope> {
        var expandedScopes: Set<OAuthScope> = []
        var scopesAwaitingExpansion = Array(grantedScopes)

        while let scope = scopesAwaitingExpansion.popLast() {
            guard expandedScopes.insert(scope).inserted else { continue }
            scopesAwaitingExpansion.append(contentsOf: implicitlyGrantedScopes[scope] ?? [])
        }

        return expandedScopes
    }

    /// Parses the scope string GitHub returns with an access token. Values arrive comma separated,
    /// but the separator has varied across endpoints, so spaces are accepted too. Scopes this build
    /// does not know about are dropped rather than treated as an error.
    static func expandedScopes(fromGrantedScopeString grantedScopeString: String?) -> Set<OAuthScope> {
        guard let grantedScopeString else { return [] }

        let grantedScopes = grantedScopeString
            .split(whereSeparator: { $0 == "," || $0 == " " })
            .compactMap { OAuthScope(rawValue: String($0)) }

        return expandedScopes(from: grantedScopes)
    }

    static func grantedScopeString(
        _ grantedScopeString: String?,
        satisfies requiredScopes: [OAuthScope]
    ) -> Bool {
        expandedScopes(fromGrantedScopeString: grantedScopeString).isSuperset(of: requiredScopes)
    }
}
