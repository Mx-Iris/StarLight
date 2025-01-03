//
//  Configs.swift
//  Components
//
//  Created by JH on 2025/1/3.
//

import Foundation
import GitHubNetworking

public enum Configs {
    public enum App {
        public static let urlScheme = "starlight"
        public static let githubID = "Ov23li4DKEAP9Ghz5xtx"
        public static let githubSecrets = "05cb9608345ba9245836ff48ae64d8f9c9b5f62c"
        public static let githubScopes: [OAuthScope] = [.readUser, .publicRepo]
        public static let githubLoginURL = URL(string: "http://github.com/login/oauth/authorize?client_id=\(githubID)&scope=\(githubScopes.scopesString)")!
    }
}
