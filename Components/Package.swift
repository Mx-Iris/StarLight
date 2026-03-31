// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

extension Package.Dependency {
    enum LocalSearchPath {
        case package(path: String, isRelative: Bool, isEnabled: Bool, traits: Set<PackageDescription.Package.Dependency.Trait> = [.defaults])
    }

    static func package(local localSearchPaths: LocalSearchPath..., remote: Package.Dependency) -> Package.Dependency {
        let currentFilePath = #filePath
        let isClonedDependency = currentFilePath.contains("/checkouts/") ||
            currentFilePath.contains("/SourcePackages/") ||
            currentFilePath.contains("/.build/")

        if isClonedDependency {
            return remote
        }
        for local in localSearchPaths {
            switch local {
            case .package(let path, let isRelative, let isEnabled, let traits):
                guard isEnabled else { continue }
                let url = if isRelative {
                    URL(fileURLWithPath: path, relativeTo: URL(fileURLWithPath: #filePath))
                } else {
                    URL(fileURLWithPath: path)
                }

                if FileManager.default.fileExists(atPath: url.path) {
                    return .package(path: url.path, traits: traits)
                }
            }
        }
        return remote
    }
}

let package = Package(
    name: "Components",
    platforms: [.macOS(.v13)],
    products: [
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
            local: .package(
                path: "/Volumes/Repositories/Private/Personal/Library/Multi/GitHubServices",
                isRelative: false,
                isEnabled: true
            ),
            .package(
                path: "../GitHubServices",
                isRelative: true,
                isEnabled: false
            ),
            remote: .package(
                url: "https://github.com/Mx-Iris/GitHubServices",
                branch: "main"
            )
        ),
        .package(
            local: .package(
                path: "/Volumes/Repositories/Private/Fork/Library/DSFQuickActionBar",
                isRelative: false,
                isEnabled: true
            ),
            .package(
                path: "/Volumes/Code/Personal/DSFQuickActionBar",
                isRelative: true,
                isEnabled: true
            ),
            remote: .package(
                url: "https://github.com/MxIris-macOS-Library-Forks/DSFQuickActionBar",
                branch: "main"
            )
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
            from: "0.4.0"
        ),
        .package(
            url: "https://github.com/Mx-Iris/CocoaCoordinator",
            from: "0.4.1"
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
            from: "0.2.0"
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
    ],
    swiftLanguageModes: [.v5],
)
