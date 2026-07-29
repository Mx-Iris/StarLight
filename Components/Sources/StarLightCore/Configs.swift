import Foundation
import GitHubNetworking

public enum Configs {
    public enum App {
        public static let githubID = "Ov23li4DKEAP9Ghz5xtx"
    }
}

/// How much of the user's GitHub account StarLight is allowed to search. The app asks for the
/// narrower level by default and only widens it when the user explicitly opts in from Settings,
/// because widening means asking them to authorize again.
public enum RepositoryAccessLevel: Sendable, Hashable, CaseIterable {
    /// Public repositories only. What every build up to 1.7 requested.
    case publicRepositoriesOnly

    /// Adds private repositories, plus organizations whose membership the user has kept private.
    case includingPrivateRepositories

    var scopes: [OAuthScope] {
        switch self {
        case .publicRepositoriesOnly:
            [.readUser, .publicRepo]
        case .includingPrivateRepositories:
            // GitHub publishes no read-only scope for private repositories, so `repo` — which also
            // carries write access — is the narrowest scope that works. `read:org` is what makes
            // `GET /user/orgs` report organizations the user has not made their membership public in.
            [.readUser, .repo, .readOrg]
        }
    }
}
