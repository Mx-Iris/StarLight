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
    platforms: [.macOS(.v13)],
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
        .library(
            name: "StarLightUtilities",
            targets: ["StarLightUtilities"]
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
            url: "https://github.com/sindresorhus/Defaults",
            from: "8.2.0"
        ),
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess",
            from: "4.0.0"
        ),
        .package(
            url: "https://github.com/Mx-Iris/UIFoundation",
            branch: "main"
        ),
        .package(
            url: "https://github.com/MrKai77/Luminare",
            branch: "main"
        ),
        .package(
            url: "https://github.com/Mx-Iris/CocoaCoordinator",
            branch: "main"
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
                "StarLightUtilities",
            ]
        ),

        .target(
            name: "StarLightUI",
            dependencies: [
                .product(name: "DSFQuickActionBar", package: "DSFQuickActionBar"),
                .product(name: "Luminare", package: "Luminare"),
            ]
        ),

        .target(
            name: "StarLightUtilities",
            dependencies: [
                .product(name: "Defaults", package: "Defaults"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "UIFoundation", package: "UIFoundation"),
                .product(name: "CocoaCoordinator", package: "CocoaCoordinator"),
            ]
        ),
    ]
)
