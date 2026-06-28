import Foundation
import GitHubNetworking

public enum Configs {
    public enum App {
        public static let githubID = "Ov23li4DKEAP9Ghz5xtx"
        public static let githubScopes: [OAuthScope] = [.readUser, .publicRepo]
    }
}
