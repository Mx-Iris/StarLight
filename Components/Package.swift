// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

extension Package.Dependency {
    static func package(localPath: String, remotePath: String, branch: String) -> Package.Dependency {
        if FileManager.default.fileExists(atPath: localPath) {
            return .package(path: localPath)
        } else {
            return .package(url: remotePath, branch: branch)
        }
    }
}

let package = Package(
    name: "Components",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "StarLightCore",
            targets: ["StarLightCore"]
        ),
        .library(
            name: "StarLightUI",
            targets: ["StarLightUI"]
        ),
    ],
    dependencies: [
        .package(
            localPath: "/Volumes/Repositories/Private/Personal/Library/Multi/GitHubServices",
            remotePath: "https://github.com/Mx-Iris/GitHubServices",
            branch: "main"
        ),
        .package(
            url: "https://github.com/dagronf/DSFQuickActionBar",
            .upToNextMajor(from: "6.2.0")
        ),
        .package(
            url: "https://github.com/ChimeHQ/OAuthenticator",
            .upToNextMajor(from: "0.5.0")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "StarLightCore",
            dependencies: [
                .product(name: "GitHubModels", package: "GitHubServices"),
                .product(name: "GitHubNetworking", package: "GitHubServices"),
            ]
        ),

        .target(
            name: "StarLightUI",
            dependencies: [
                .product(name: "DSFQuickActionBar", package: "DSFQuickActionBar")
            ]
        ),
    ]
)
