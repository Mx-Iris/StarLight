# AGENTS.md

Guidance for coding agents (Claude Code, Codex, and friends) working in this repository.

`CLAUDE.md` is a symlink to this file — edit `AGENTS.md`, never the symlink.

## Project Overview

StarLight is a macOS menu bar app that searches your GitHub repositories through a Spotlight-like
quick action bar. It authenticates with GitHub OAuth **Device Flow** (no client secret shipped in
the binary, multi-device friendly), fetches two repository collections — the ones you starred, and
the ones you own plus everything under your organizations — caches them locally as JSON, and
presents a search panel triggered by a global keyboard shortcut.

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
They cover the pure decision functions: `StarredRepositoriesRefreshPolicy`,
`PersonalRepositoriesRefreshPolicy`, `RepositorySearchCatalog`, `RepositorySearchIndex`,
`OAuthScopeSatisfaction`, and `AuthenticationFailureReporter`. The app target itself has no test bundle; keep new logic testable
by pushing decisions into `StarLightCore` free functions the way those types do.

`Repository` is a MetaCodable-generated final class with no memberwise initializer, so tests build
instances through `RepositoryFixture`, which round-trips the bundled sample through JSON and patches
the fields under test.

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
  `LoginServiceDelegate` for surfacing a `DeviceCode` to the UI), `StarredRepositoriesService` and
  `PersonalRepositoriesService` (actors; fetch, cache, and refresh the two repository collections),
  their two refresh policies, `RepositorySearchCatalog` (merges the collections) and
  `RepositorySearchIndex` (matches and ranks search terms against them),
  `OAuthScopeSatisfaction` (models GitHub's scope hierarchy),
  `AuthenticationFailureReporter` (shared token-rejection detection), `RepositoryCacheLocation`
  (cache paths plus legacy-name migration), `Configs` and `RepositoryAccessLevel` (GitHub client ID
  and the two OAuth scope sets), and `Keychains` (internal token storage)
- **StarLightUI** — the `AsyncButton` family only (SwiftUI button that runs an async operation and
  surfaces its error). The menu bar and quick action bar code lives in the app layer, not here.
- **StarLightUtilities** — the `@UserDefault` property wrapper (wraps Defaults, caches the last
  value behind FoundationToolbox's `@RecursiveLock`)
- **StarLightResources** — SwiftGen-generated Octicons asset catalog

### Key Patterns

- **`AppServices`** — a plain service locator holding `LoginService`,
  `StarredRepositoriesService`, and `PersonalRepositoriesService`, injected through coordinators
  into view models. Its `init` pushes stored preferences back into the services, since each service
  otherwise starts on its own built-in defaults.
- **Root authentication gate** — `AppRoute` declares `requiresAuthentication`; `prepareTransition`
  rewrites any protected route to `.login` when there is no token, so no call site has to check
  login state itself
- **Authentication failure** — both repository services report through
  `AuthenticationFailureReporter`, which posts `.gitHubAuthenticationFailed` when GitHub rejects the
  token; `AppCoordinator` answers with a single `.authenticationFailed` route that composes three
  transitions: cancel the quick action bar, dismiss Settings if open, and present Login carrying an
  error message
- **OAuth scopes are a user choice** — `RepositoryAccessLevel` carries the two scope sets.
  `.publicRepositoriesOnly` (`read:user`, `public_repo`) is the default; `.includingPrivateRepositories`
  (`read:user`, `repo`, `read:org`) is requested only after the user turns on *Include Private
  Repositories* and confirms the reauthorization prompt. GitHub publishes no read-only scope for
  private repositories, which is why the wider set carries write access. Never widen the default
  set — existing tokens would silently stop being sufficient.
- **Coordinator lifecycle** — routed `SceneCoordinator` instances are added and pruned
  automatically by CocoaCoordinator; do not call `addChild` or `removeChild` by hand for the Login
  and Settings scenes
- **`ViewModel<Route>`** — base class holding `appServices` and an unowned `router` for triggering
  route transitions
- **`StarredRepositoriesService`** — Swift actor with `@Published` state and a repository-change
  identifier. It loads the cache before starting any network work, probes the newest and last
  starred-repository pages on the configured timer, performs a serial full refresh only when
  membership changes or the last full refresh is at least 24 hours old, and gives manual full
  refreshes priority over automatic probes without ever overlapping two paginating tasks. The
  repository array is persisted to `~/Documents/StarredRepositories.json`; user and full-refresh
  metadata go to the companion `StarredRepositoriesMetadata.json`. See
  [`Documentations/StarredRepositoriesRefreshOptimization.md`](Documentations/StarredRepositoriesRefreshOptimization.md).
- **`PersonalRepositoriesService`** — the same shape, for repositories you own plus everything under
  your organizations. It walks `/user/repos` (`affiliation=owner,organization_member`), `/user/orgs`,
  and `/orgs/{org}/repos?type=all` in sequence, deduplicating by full name. The first and third calls
  are not redundant: without `read:org`, `/user/orgs` omits organizations whose membership is
  private, so only the first call reaches those. There is no lightweight probe here — these
  endpoints return bare arrays with no last-page number, so the automatic refresh is throttled to a
  30-minute minimum interval instead, and a manual refresh ignores it. Stays inert until
  `setEnabled(true)`. Caches to `~/Documents/PersonalRepositories.json` and its metadata companion.
  See [`Documentations/PersonalRepositoriesSearch.md`](Documentations/PersonalRepositoriesSearch.md).
- **`RepositorySearchCatalog`** — merges the two collections for search (personal first, dedupe by
  full name, drop private repositories unless the user opted in), and owns the word splitting the
  search shares. The private filter lives here, at the point of use, so the Settings toggle takes
  effect instantly and covers both sources; it does not delete anything already cached.
- **`RepositorySearchIndex`** — matching and ranking, over a merged list with every searchable field
  pre-split into words. The rules mirror GitHub's own "Search stars" box, verified against a live
  account: only name, description, and topics are searched (never the owner, language, or README);
  the name matches by prefix on the whole name or any camel-case/punctuation-delimited word inside
  it; description and topics match whole words only; every query word must match, possibly through
  different fields. Ranking scores name hits above topic hits above description hits, and ties keep
  the incoming order so the "personal first, then recently starred" ordering survives. Indexing is
  what makes this affordable — re-splitting 2000+ repositories per keystroke costs ~50 ms against
  ~1–3 ms for an indexed query — so `MainActionBarController` builds the index off the main actor
  when the panel opens and caches it until a collection refreshes or the private-repository
  setting changes. See
  [`Documentations/RepositorySearchMatching.md`](Documentations/RepositorySearchMatching.md).
- **Token storage** — `Keychains` uses FoundationToolbox's `@Keychain` wrapper with
  `synchronizable: false`, so tokens stay on the current device and never reach the iCloud
  keychain. The service name is the hardcoded `com.JH.StarLight.Keychains` in every configuration,
  so Debug and Release builds share one keychain item.
- **Quick action bar lifecycle** — `MainActionBarController` tracks `preparing` / `presented` /
  `dismissing` explicitly. Pressing the shortcut again while the panel is dismissing calls
  `QuickActionBar.resumePresentation()`, reversing the animation on the same panel instead of
  waiting for `didClose` and rebuilding it.
- **Menu bar** — `AppStatusItemController` (a `StatusItemController` subclass) builds its menu with
  the `MenuBuilder` DSL and swaps the star icon for a spinner while either repository service's
  `state` is not `.idle`
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
