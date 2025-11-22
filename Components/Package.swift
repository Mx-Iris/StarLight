// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

extension Package.Dependency {
    static func package(localPath: String, remotePath: String, branch: String, usingLocal: Bool = true) -> Package.Dependency {
        if FileManager.default.fileExists(atPath: localPath), usingLocal {
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
        .library(
            name: "StarLightResources",
            targets: ["StarLightResources"]
        ),
    ],
    dependencies: [
        .package(
            localPath: "/Volumes/Repositories/Private/Personal/Library/Multi/GitHubServices",
            remotePath: "https://github.com/Mx-Iris/GitHubServices",
            branch: "main",
            usingLocal: false,
        ),
        .package(
            localPath: "/Volumes/Repositories/Private/Fork/Library/DSFQuickActionBar",
            remotePath: "https://github.com/MxIris-macOS-Library-Forks/DSFQuickActionBar",
            branch: "main",
            usingLocal: true,
        ),
//        .package(
//            url: "https://github.com/MxIris-macOS-Library-Forks/DSFQuickActionBar",
//            branch: "main"
//        ),
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
            branch: "main",
        ),
        .package(
            url: "https://github.com/Mx-Iris/CocoaCoordinator",
            branch: "main",
        ),
        .package(
            url: "https://github.com/sindresorhus/KeyboardShortcuts",
            from: "2.0.0"
        ),
        .package(
            url: "https://github.com/SDWebImage/SDWebImageSwiftUI",
            from: "3.0.0"
        ),
        .package(
            url: "https://github.com/hexedbits/StatusItemController",
            from: "2.0.0"
        ),
        .package(
            url: "https://github.com/j-f1/MenuBuilder",
            from: "3.0.0"
        ),
        .package(
            url: "https://github.com/Mx-Iris/SFSymbols",
            branch: "main",
        ),
        .package(
            url: "https://github.com/sindresorhus/LaunchAtLogin-Modern",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/exyte/ProgressIndicatorView",
            from: "1.1.0"
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
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
                .product(name: "StatusItemController", package: "StatusItemController"),
                .product(name: "MenuBuilder", package: "MenuBuilder"),
                .product(name: "SFSymbols", package: "SFSymbols"),
                .product(name: "ProgressIndicatorView", package: "ProgressIndicatorView"),
            ]
        ),

        .target(
            name: "StarLightUtilities",
            dependencies: [
                .product(name: "Defaults", package: "Defaults"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "UIFoundation", package: "UIFoundation"),
                .product(name: "CocoaCoordinator", package: "CocoaCoordinator"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
            ]
        ),
        .target(
            name: "StarLightResources",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
