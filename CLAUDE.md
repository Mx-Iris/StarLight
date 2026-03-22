# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StarLight is a macOS menu bar app that lets you search GitHub starred repositories using a Spotlight-like quick action bar (DSFQuickActionBar). It authenticates via GitHub OAuth, fetches starred repos, caches them locally as JSON, and presents a keyboard-shortcut-triggered search panel.

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

- **StarLightCore** — business logic: `LoginService` (GitHub OAuth), `RepositoriesService` (actor, fetches/caches starred repos), `Configs`, `KeychainStorage`
- **StarLightUI** — UI components: `AsyncButton`, quick action bar integration, status item helpers
- **StarLightUtilities** — cross-cutting: `@UserDefault` property wrapper (wraps Defaults), `@Keychain` property wrapper (wraps KeychainAccess)
- **StarLightResources** — bundled assets

### Key Patterns

- **`AppServices`** — simple service locator holding `LoginService` and `RepositoriesService`, injected through coordinators into view models
- **`ViewModel<Route>`** — base class holding `appServices` and a `router` reference for triggering route transitions
- **`RepositoriesService`** — Swift actor with `@Published` state, auto-refreshes on timer, persists to `~/Documents/Repositories.json`
- **`KeychainStorage`** — uses `@Keychain` property wrapper for token persistence
- **Menu bar** — `AppStatusItemController` (StatusItemController subclass) builds the menu via `MenuBuilder` DSL
- **Activation policy** — toggles between `.regular` (shows dock icon + windows) and `.accessory` (menu-bar-only) based on login state and window visibility

### Dependencies (via Components/Package.swift)

The `Package.swift` has a `localPath`/`remotePath` pattern allowing local checkout overrides. Key dependencies:
- `GitHubServices` (GitHubModels + GitHubNetworking) — GitHub API client
- `DSFQuickActionBar` — Spotlight-like search panel
- `Defaults` — UserDefaults wrapper
- `KeychainAccess` — Keychain wrapper
- `CocoaCoordinator` — coordinator pattern framework
- `KeyboardShortcuts` — global hotkey registration
- `SDWebImageSwiftUI` — async image loading
- `StatusItemController` — menu bar item management

### Local Package: swift-syntax

The workspace includes a local `swift-syntax` package (aggregation stubs only). This is a build-time dependency workaround, not application code.
