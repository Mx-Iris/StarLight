# AGENTS.md

Guidance for coding agents (Claude Code, Codex, and friends) working in this repository.

`CLAUDE.md` is a symlink to this file — edit `AGENTS.md`, never the symlink.

## Project Overview

StarLight is a macOS menu bar app that searches your GitHub starred repositories through a
Spotlight-like quick action bar. It authenticates with GitHub OAuth **Device Flow** (no client
secret shipped in the binary, multi-device friendly), fetches starred repositories, caches them
locally as JSON, and presents a search panel triggered by a global keyboard shortcut.

- **Platform:** macOS 13.0+ (app target deployment target; the project-level configs say 15.2, the
  target-level 13.0 wins)
- **Swift:** `Components/Package.swift` uses swift-tools-version 6.2 with `swiftLanguageModes: [.v5]`;
  the Xcode project builds with `SWIFT_VERSION = 5.0`
- **Bundle ID:** `dev.JH.StarLight` (Debug) / `com.JH.StarLight` (Release)
- **Current marketing version:** 1.7

## Build and Test Commands

Open `StarLight.xcworkspace` (not the `.xcodeproj`) — the workspace includes both the app project
and the local `swift-syntax` package.

```bash
# Build the app (workspace, not project)
xcodebuild -workspace StarLight.xcworkspace -scheme StarLight -configuration Debug build 2>&1 | xcsift

# Build the Components SPM package standalone
cd Components && swift package update && swift build 2>&1 | xcsift

# Run the package tests
cd Components && swift test 2>&1 | xcsift
```

Tests live in `Components/Tests/StarLightCoreTests` and use swift-testing (`@Test` / `#expect`).
They cover `RepositoriesRefreshPolicy` — the pure decision functions behind the refresh strategy.
The app target itself has no test bundle; keep new logic testable by pushing decisions into
`StarLightCore` free functions the way `RepositoriesRefreshPolicy` does.

## Architecture

### Coordinator Pattern (CocoaCoordinator)

Navigation is driven by a coordinator tree, not storyboards or SwiftUI `NavigationStack`.
`AppDelegate` owns `AppServices`, the root `AppCoordinator`, and `AppStatusItemController`.

- `AppCoordinator` — subclasses `CocoaCoordinator.AppCoordinator<AppRoute>`; owns the
  authentication gate and holds `MainCoordinator` strongly
- `LoginCoordinator` — `SceneCoordinator` presenting the login window; drives Device Flow
- `SettingsCoordinator` — `SceneCoordinator` presenting the settings window
- `MainCoordinator` — owns the quick action bar controller; only exposes `.present` / `.cancel`

Each coordinator defines a `Route` enum and a `prepareTransition(for:)` method. Parent-child
communication uses `Delegate` protocols nested inside the coordinators.

### Two-Layer Structure

| Layer | Location | Description |
|-------|----------|-------------|
| **App layer** | `StarLight/` | AppKit coordinators, view controllers, window controllers, SwiftUI views |
| **Components SPM** | `Components/` | Reusable libraries split into 4 targets |

### Components Package Targets

- **StarLightCore** — business logic: `LoginService` (actor; GitHub OAuth Device Flow, plus
  `LoginServiceDelegate` for surfacing a `DeviceCode` to the UI), `RepositoriesService` (actor;
  fetches, caches, and refreshes starred repositories), `RepositoriesRefreshPolicy` (internal pure
  decision functions, unit tested), `Configs` (GitHub client ID and OAuth scopes), and `Keychains`
  (internal token storage)
- **StarLightUI** — the `AsyncButton` family only (SwiftUI button that runs an async operation and
  surfaces its error). The menu bar and quick action bar code lives in the app layer, not here.
- **StarLightUtilities** — the `@UserDefault` property wrapper (wraps Defaults, caches the last
  value behind FoundationToolbox's `@RecursiveLock`)
- **StarLightResources** — SwiftGen-generated Octicons asset catalog

### Key Patterns

- **`AppServices`** — a plain service locator holding `LoginService` and `RepositoriesService`,
  injected through coordinators into view models
- **Root authentication gate** — `AppRoute` declares `requiresAuthentication`; `prepareTransition`
  rewrites any protected route to `.login` when there is no token, so no call site has to check
  login state itself
- **Authentication failure** — `RepositoriesService` posts
  `.repositoriesServiceAuthenticationFailed` when GitHub rejects the token; `AppCoordinator`
  answers with a single `.authenticationFailed` route that composes three transitions: cancel the
  quick action bar, dismiss Settings if open, and present Login carrying an error message
- **Coordinator lifecycle** — routed `SceneCoordinator` instances are added and pruned
  automatically by CocoaCoordinator; do not call `addChild` or `removeChild` by hand for the Login
  and Settings scenes
- **`ViewModel<Route>`** — base class holding `appServices` and an unowned `router` for triggering
  route transitions
- **`RepositoriesService`** — Swift actor with `@Published` state and a repository-change
  identifier. It loads the cache before starting any network work, probes the newest and last
  starred-repository pages on the configured timer, performs a serial full refresh only when
  membership changes or the last full refresh is at least 24 hours old, and gives manual full
  refreshes priority over automatic probes without ever overlapping two paginating tasks. The
  repository array is persisted to `~/Documents/Repositories.json`; user and full-refresh metadata
  go to the companion `RepositoriesMetadata.json`. See
  [`Documentations/StarredRepositoriesRefreshOptimization.md`](Documentations/StarredRepositoriesRefreshOptimization.md).
- **Token storage** — `Keychains` uses FoundationToolbox's `@Keychain` wrapper with
  `synchronizable: false`, so tokens stay on the current device and never reach the iCloud
  keychain. The service name is the hardcoded `com.JH.StarLight.Keychains` in every configuration,
  so Debug and Release builds share one keychain item.
- **Quick action bar lifecycle** — `MainActionBarController` tracks `preparing` / `presented` /
  `dismissing` explicitly. Pressing the shortcut again while the panel is dismissing calls
  `QuickActionBar.resumePresentation()`, reversing the animation on the same panel instead of
  waiting for `didClose` and rebuilding it.
- **Menu bar** — `AppStatusItemController` (a `StatusItemController` subclass) builds its menu with
  the `MenuBuilder` DSL and swaps the star icon for a spinner while `RepositoriesService.state` is
  not `.idle`
- **Activation policy** — toggles between `.regular` (dock icon plus windows) and `.accessory`
  (menu bar only). Login and Settings switch to `.regular` when shown; closing the Settings window
  switches back to `.accessory`.

### Dependencies (via `Components/Package.swift`)

`Package.swift` defines a `local`/`remote` helper letting a local checkout override a remote
package during development, while cloned copies of this package always resolve the remote.

| Package | Used for |
|---------|----------|
| `GitHubServices` (GitHubModels + GitHubNetworking) | GitHub API client; resolves a local checkout first, remote `main` as fallback |
| `UIFoundation` (with the `QuickActionBar` trait) | The Spotlight-like search panel; remote `0.13.0`+ |
| `CocoaCoordinator` | Coordinator framework; local checkout first, remote `main` as fallback |
| `Defaults` | UserDefaults wrapper backing `@UserDefault` and the settings screen |
| `FrameworkToolbox` (FoundationToolbox) | `@Keychain` and `@RecursiveLock` |
| `KeychainAccess` | Legacy dependency of `StarLightUtilities`; token storage no longer goes through it |
| `KeyboardShortcuts` | Global hotkey registration and the recorder in Settings |
| `LaunchAtLogin-Modern` | The "Launch at login" toggle |
| `SDWebImageSwiftUI` | Async image loading for repository owner avatars |
| `StatusItemController` | Menu bar item management |
| `MenuBuilder` | Declarative `NSMenu` construction |
| `SFSymbols` | Type-safe SF Symbol names |
| `ProgressIndicatorView` | Progress UI |

Note: this app uses **UIFoundation's** `QuickActionBar`, not `DSFQuickActionBar`. Older docs and
commit messages may still mention the latter.

### Local Package: swift-syntax

The workspace includes a local `swift-syntax` package (aggregation stubs only). It is a build-time
dependency workaround, not application code.

## Releasing

Releases are automated by `.github/workflows/release.yml` (build → sign → notarize → staple → zip →
GitHub Release), with `scripts/release.sh` as the same pipeline runnable locally.

**Hard rule: `ReleaseNotes/<tag>.md` must exist and be non-empty before you push a `vX.Y` tag.**
CI fails before any signing happens if it is missing. Release notes are public-facing and written
in English; see [`ReleaseNotes/README.md`](ReleaseNotes/README.md) for the expected shape and
[`Documentations/ReleaseCI.md`](Documentations/ReleaseCI.md) for the full pipeline.

## Documentation Conventions

- Long-form docs live in `Documentations/` and are written in Chinese (they are internal design and
  evolution notes). Public-facing text — `README.md`, `ReleaseNotes/`, this file, commit messages,
  and code comments — is written in English.
- [`Documentations/README.md`](Documentations/README.md) is the index. **Adding or renaming a
  document means updating that index in the same change.**
- Land documentation together with the code change it describes, not in a follow-up pass.
