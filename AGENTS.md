# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

StarLight is a macOS menu bar app that lets you search GitHub starred repositories using a Spotlight-like quick action bar (DSFQuickActionBar). It authenticates via GitHub OAuth **Device Flow** (no client secret required, multi-device friendly), fetches starred repos, caches them locally as JSON, and presents a keyboard-shortcut-triggered search panel.

- **Platform:** macOS 13.0+ (deployment target), built with AppKit + SwiftUI hybrid
- **Swift tools version:** 5.10 (Components SPM package), Swift 5 in Xcode project
- **Bundle ID:** `dev.JH.StarLight` (Debug) / `com.JH.StarLight` (Release)

## Build Commands

Open `StarLight.xcworkspace` (not the `.xcodeproj`) — the workspace includes both the app project and the `swift-syntax` local package.

```bash
# Build via xcodebuild (use workspace, not project)
xcodebuild -workspace StarLight.xcworkspace -scheme StarLight -configuration Debug build 2>&1 | xcsift

# Build the Components SPM package standalone
cd Components && swift package update && swift build 2>&1 | xcsift
```

There are no tests configured in this project.

## Architecture

### Coordinator Pattern (CocoaCoordinator)

Navigation is driven by a coordinator tree, not storyboards or SwiftUI NavigationStack:

- `AppCoordinator` — root coordinator, decides initial route (login vs settings vs accessory mode)
- `LoginCoordinator` — presents login window, handles OAuth flow via `ASWebAuthenticationSession`
- `SettingsCoordinator` — presents settings window
- `MainCoordinator` — manages the quick-action-bar search panel, triggered by global keyboard shortcut

Each coordinator defines a `Route` enum and a `prepareTransition(for:)` method. Parent-child communication uses delegate protocols nested inside coordinators.

### Two-Layer Structure

| Layer | Location | Description |
|-------|----------|-------------|
| **App layer** | `StarLight/` | AppKit coordinators, view controllers, window controllers, SwiftUI views |
| **Components SPM** | `Components/` | Reusable libraries split into 4 targets |

### Components Package Targets

- **StarLightCore** — business logic: `LoginService` (GitHub OAuth Device Flow + `LoginServiceDelegate` for surfacing `DeviceCode` to UI), `RepositoriesService` (actor, fetches/caches starred repos), `Configs`, `Keychains`
- **StarLightUI** — UI components: `AsyncButton`, quick action bar integration, status item helpers
- **StarLightUtilities** — cross-cutting: `@UserDefault` property wrapper (wraps Defaults), `@Keychain` property wrapper (wraps KeychainAccess)
- **StarLightResources** — bundled assets

### Key Patterns

- **`AppServices`** — simple service locator holding `LoginService` and `RepositoriesService`, injected through coordinators into view models
- **Root authentication gate** — the root coordinator subclasses `CocoaCoordinator.AppCoordinator`; `prepareTransition(for:)` redirects protected routes, while `.authenticationFailed` composes main cancellation, settings dismissal, and login presentation
- **Coordinator lifecycle** — routed `SceneCoordinator` instances are added and pruned automatically by CocoaCoordinator; do not manually call `addChild` or `removeChild` for Login and Settings scenes
- **`ViewModel<Route>`** — base class holding `appServices` and a `router` reference for triggering route transitions
- **`RepositoriesService`** — Swift actor with `@Published` state and repository-change identifiers. It loads the cache before starting network work, probes the newest and last starred-repository pages on the configured timer, performs a serial full refresh only when membership changes or the last full refresh is at least 24 hours old, and gives manual full refreshes priority over automatic probes without overlapping pagination requests. It preserves the repository array in `~/Documents/Repositories.json` and stores user/full-refresh metadata in the companion `RepositoriesMetadata.json` file.
- **`KeychainStorage`** — uses `@Keychain` property wrapper for token persistence
- **Menu bar** — `AppStatusItemController` (StatusItemController subclass) builds the menu via `MenuBuilder` DSL
- **Activation policy** — toggles between `.regular` (shows dock icon + windows) and `.accessory` (menu-bar-only) based on login state and window visibility
- **Quick action bar lifecycle** — `MainActionBarController` 区分 preparation、presented 与 dismissing；dismissing 期间再次触发快捷键时调用 `QuickActionBar.resumePresentation()`，在同一个 panel 上反向接续动画，不等待 `didClose` 后重建。

### Dependencies (via Components/Package.swift)

The `Package.swift` has a `localPath`/`remotePath` pattern allowing local checkout overrides. Key dependencies:
- `GitHubServices` (GitHubModels + GitHubNetworking) — GitHub API client; local development resolves the sibling `../GitHubServices` checkout before the remote `main` fallback
- `UIFoundation`（启用 `QuickActionBar` trait）— 提供 Spotlight-like search panel；通过远程 `0.13.0` 或更高兼容版本解析
- `Defaults` — UserDefaults wrapper
- `KeychainAccess` — Keychain wrapper
- `CocoaCoordinator` — coordinator pattern framework, resolved from the local macOS library checkout during development with `main` as the remote fallback
- `KeyboardShortcuts` — global hotkey registration
- `SDWebImageSwiftUI` — async image loading
- `StatusItemController` — menu bar item management

### Local Package: swift-syntax

The workspace includes a local `swift-syntax` package (aggregation stubs only). This is a build-time dependency workaround, not application code.
