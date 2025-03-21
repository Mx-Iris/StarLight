// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum Assets {
  public enum Octicons {
    public static let accessibility16 = ImageAsset(name: "accessibility-16")
    public static let accessibilityInset16 = ImageAsset(name: "accessibility-inset-16")
    public static let alert16 = ImageAsset(name: "alert-16")
    public static let alert24 = ImageAsset(name: "alert-24")
    public static let alertFill12 = ImageAsset(name: "alert-fill-12")
    public static let alertFill16 = ImageAsset(name: "alert-fill-16")
    public static let alertFill24 = ImageAsset(name: "alert-fill-24")
    public static let apps16 = ImageAsset(name: "apps-16")
    public static let archive16 = ImageAsset(name: "archive-16")
    public static let archive24 = ImageAsset(name: "archive-24")
    public static let arrowBoth16 = ImageAsset(name: "arrow-both-16")
    public static let arrowBoth24 = ImageAsset(name: "arrow-both-24")
    public static let arrowDown16 = ImageAsset(name: "arrow-down-16")
    public static let arrowDown24 = ImageAsset(name: "arrow-down-24")
    public static let arrowDownLeft16 = ImageAsset(name: "arrow-down-left-16")
    public static let arrowDownLeft24 = ImageAsset(name: "arrow-down-left-24")
    public static let arrowDownRight16 = ImageAsset(name: "arrow-down-right-16")
    public static let arrowDownRight24 = ImageAsset(name: "arrow-down-right-24")
    public static let arrowLeft16 = ImageAsset(name: "arrow-left-16")
    public static let arrowLeft24 = ImageAsset(name: "arrow-left-24")
    public static let arrowRight16 = ImageAsset(name: "arrow-right-16")
    public static let arrowRight24 = ImageAsset(name: "arrow-right-24")
    public static let arrowSwitch16 = ImageAsset(name: "arrow-switch-16")
    public static let arrowSwitch24 = ImageAsset(name: "arrow-switch-24")
    public static let arrowUp16 = ImageAsset(name: "arrow-up-16")
    public static let arrowUp24 = ImageAsset(name: "arrow-up-24")
    public static let arrowUpLeft16 = ImageAsset(name: "arrow-up-left-16")
    public static let arrowUpLeft24 = ImageAsset(name: "arrow-up-left-24")
    public static let arrowUpRight16 = ImageAsset(name: "arrow-up-right-16")
    public static let arrowUpRight24 = ImageAsset(name: "arrow-up-right-24")
    public static let beaker16 = ImageAsset(name: "beaker-16")
    public static let beaker24 = ImageAsset(name: "beaker-24")
    public static let bell16 = ImageAsset(name: "bell-16")
    public static let bell24 = ImageAsset(name: "bell-24")
    public static let bellFill16 = ImageAsset(name: "bell-fill-16")
    public static let bellFill24 = ImageAsset(name: "bell-fill-24")
    public static let bellSlash16 = ImageAsset(name: "bell-slash-16")
    public static let bellSlash24 = ImageAsset(name: "bell-slash-24")
    public static let blocked16 = ImageAsset(name: "blocked-16")
    public static let blocked24 = ImageAsset(name: "blocked-24")
    public static let bold16 = ImageAsset(name: "bold-16")
    public static let bold24 = ImageAsset(name: "bold-24")
    public static let book16 = ImageAsset(name: "book-16")
    public static let book24 = ImageAsset(name: "book-24")
    public static let bookmark16 = ImageAsset(name: "bookmark-16")
    public static let bookmark24 = ImageAsset(name: "bookmark-24")
    public static let bookmarkFill24 = ImageAsset(name: "bookmark-fill-24")
    public static let bookmarkSlash16 = ImageAsset(name: "bookmark-slash-16")
    public static let bookmarkSlash24 = ImageAsset(name: "bookmark-slash-24")
    public static let bookmarkSlashFill24 = ImageAsset(name: "bookmark-slash-fill-24")
    public static let briefcase16 = ImageAsset(name: "briefcase-16")
    public static let briefcase24 = ImageAsset(name: "briefcase-24")
    public static let broadcast16 = ImageAsset(name: "broadcast-16")
    public static let broadcast24 = ImageAsset(name: "broadcast-24")
    public static let browser16 = ImageAsset(name: "browser-16")
    public static let browser24 = ImageAsset(name: "browser-24")
    public static let bug16 = ImageAsset(name: "bug-16")
    public static let bug24 = ImageAsset(name: "bug-24")
    public static let cache16 = ImageAsset(name: "cache-16")
    public static let calendar16 = ImageAsset(name: "calendar-16")
    public static let calendar24 = ImageAsset(name: "calendar-24")
    public static let check16 = ImageAsset(name: "check-16")
    public static let check24 = ImageAsset(name: "check-24")
    public static let checkCircle16 = ImageAsset(name: "check-circle-16")
    public static let checkCircle24 = ImageAsset(name: "check-circle-24")
    public static let checkCircleFill12 = ImageAsset(name: "check-circle-fill-12")
    public static let checkCircleFill16 = ImageAsset(name: "check-circle-fill-16")
    public static let checkCircleFill24 = ImageAsset(name: "check-circle-fill-24")
    public static let checkbox16 = ImageAsset(name: "checkbox-16")
    public static let checkbox24 = ImageAsset(name: "checkbox-24")
    public static let checklist16 = ImageAsset(name: "checklist-16")
    public static let checklist24 = ImageAsset(name: "checklist-24")
    public static let chevronDown12 = ImageAsset(name: "chevron-down-12")
    public static let chevronDown16 = ImageAsset(name: "chevron-down-16")
    public static let chevronDown24 = ImageAsset(name: "chevron-down-24")
    public static let chevronLeft16 = ImageAsset(name: "chevron-left-16")
    public static let chevronLeft24 = ImageAsset(name: "chevron-left-24")
    public static let chevronRight12 = ImageAsset(name: "chevron-right-12")
    public static let chevronRight16 = ImageAsset(name: "chevron-right-16")
    public static let chevronRight24 = ImageAsset(name: "chevron-right-24")
    public static let chevronUp12 = ImageAsset(name: "chevron-up-12")
    public static let chevronUp16 = ImageAsset(name: "chevron-up-16")
    public static let chevronUp24 = ImageAsset(name: "chevron-up-24")
    public static let circle16 = ImageAsset(name: "circle-16")
    public static let circle24 = ImageAsset(name: "circle-24")
    public static let circleSlash16 = ImageAsset(name: "circle-slash-16")
    public static let circleSlash24 = ImageAsset(name: "circle-slash-24")
    public static let clock16 = ImageAsset(name: "clock-16")
    public static let clock24 = ImageAsset(name: "clock-24")
    public static let clockFill16 = ImageAsset(name: "clock-fill-16")
    public static let clockFill24 = ImageAsset(name: "clock-fill-24")
    public static let cloud16 = ImageAsset(name: "cloud-16")
    public static let cloud24 = ImageAsset(name: "cloud-24")
    public static let cloudOffline16 = ImageAsset(name: "cloud-offline-16")
    public static let cloudOffline24 = ImageAsset(name: "cloud-offline-24")
    public static let code16 = ImageAsset(name: "code-16")
    public static let code24 = ImageAsset(name: "code-24")
    public static let codeOfConduct16 = ImageAsset(name: "code-of-conduct-16")
    public static let codeOfConduct24 = ImageAsset(name: "code-of-conduct-24")
    public static let codeReview16 = ImageAsset(name: "code-review-16")
    public static let codeReview24 = ImageAsset(name: "code-review-24")
    public static let codeSquare16 = ImageAsset(name: "code-square-16")
    public static let codeSquare24 = ImageAsset(name: "code-square-24")
    public static let codescan16 = ImageAsset(name: "codescan-16")
    public static let codescan24 = ImageAsset(name: "codescan-24")
    public static let codescanCheckmark16 = ImageAsset(name: "codescan-checkmark-16")
    public static let codescanCheckmark24 = ImageAsset(name: "codescan-checkmark-24")
    public static let codespaces16 = ImageAsset(name: "codespaces-16")
    public static let codespaces24 = ImageAsset(name: "codespaces-24")
    public static let columns16 = ImageAsset(name: "columns-16")
    public static let columns24 = ImageAsset(name: "columns-24")
    public static let commandPalette16 = ImageAsset(name: "command-palette-16")
    public static let commandPalette24 = ImageAsset(name: "command-palette-24")
    public static let comment16 = ImageAsset(name: "comment-16")
    public static let comment24 = ImageAsset(name: "comment-24")
    public static let commentDiscussion16 = ImageAsset(name: "comment-discussion-16")
    public static let commentDiscussion24 = ImageAsset(name: "comment-discussion-24")
    public static let commit24 = ImageAsset(name: "commit-24")
    public static let container16 = ImageAsset(name: "container-16")
    public static let container24 = ImageAsset(name: "container-24")
    public static let copilot16 = ImageAsset(name: "copilot-16")
    public static let copilot24 = ImageAsset(name: "copilot-24")
    public static let copilot48 = ImageAsset(name: "copilot-48")
    public static let copilot96 = ImageAsset(name: "copilot-96")
    public static let copilotError16 = ImageAsset(name: "copilot-error-16")
    public static let copilotWarning16 = ImageAsset(name: "copilot-warning-16")
    public static let copy16 = ImageAsset(name: "copy-16")
    public static let copy24 = ImageAsset(name: "copy-24")
    public static let cpu16 = ImageAsset(name: "cpu-16")
    public static let cpu24 = ImageAsset(name: "cpu-24")
    public static let creditCard16 = ImageAsset(name: "credit-card-16")
    public static let creditCard24 = ImageAsset(name: "credit-card-24")
    public static let crossReference16 = ImageAsset(name: "cross-reference-16")
    public static let crossReference24 = ImageAsset(name: "cross-reference-24")
    public static let dash16 = ImageAsset(name: "dash-16")
    public static let dash24 = ImageAsset(name: "dash-24")
    public static let database16 = ImageAsset(name: "database-16")
    public static let database24 = ImageAsset(name: "database-24")
    public static let dependabot16 = ImageAsset(name: "dependabot-16")
    public static let dependabot24 = ImageAsset(name: "dependabot-24")
    public static let desktopDownload16 = ImageAsset(name: "desktop-download-16")
    public static let desktopDownload24 = ImageAsset(name: "desktop-download-24")
    public static let deviceCamera16 = ImageAsset(name: "device-camera-16")
    public static let deviceCameraVideo16 = ImageAsset(name: "device-camera-video-16")
    public static let deviceCameraVideo24 = ImageAsset(name: "device-camera-video-24")
    public static let deviceDesktop16 = ImageAsset(name: "device-desktop-16")
    public static let deviceDesktop24 = ImageAsset(name: "device-desktop-24")
    public static let deviceMobile16 = ImageAsset(name: "device-mobile-16")
    public static let deviceMobile24 = ImageAsset(name: "device-mobile-24")
    public static let devices16 = ImageAsset(name: "devices-16")
    public static let devices24 = ImageAsset(name: "devices-24")
    public static let diamond16 = ImageAsset(name: "diamond-16")
    public static let diamond24 = ImageAsset(name: "diamond-24")
    public static let diff16 = ImageAsset(name: "diff-16")
    public static let diff24 = ImageAsset(name: "diff-24")
    public static let diffAdded16 = ImageAsset(name: "diff-added-16")
    public static let diffIgnored16 = ImageAsset(name: "diff-ignored-16")
    public static let diffModified16 = ImageAsset(name: "diff-modified-16")
    public static let diffRemoved16 = ImageAsset(name: "diff-removed-16")
    public static let diffRenamed16 = ImageAsset(name: "diff-renamed-16")
    public static let discussionClosed16 = ImageAsset(name: "discussion-closed-16")
    public static let discussionClosed24 = ImageAsset(name: "discussion-closed-24")
    public static let discussionDuplicate16 = ImageAsset(name: "discussion-duplicate-16")
    public static let discussionDuplicate24 = ImageAsset(name: "discussion-duplicate-24")
    public static let discussionOutdated16 = ImageAsset(name: "discussion-outdated-16")
    public static let discussionOutdated24 = ImageAsset(name: "discussion-outdated-24")
    public static let dot16 = ImageAsset(name: "dot-16")
    public static let dot24 = ImageAsset(name: "dot-24")
    public static let dotFill16 = ImageAsset(name: "dot-fill-16")
    public static let dotFill24 = ImageAsset(name: "dot-fill-24")
    public static let download16 = ImageAsset(name: "download-16")
    public static let download24 = ImageAsset(name: "download-24")
    public static let duplicate16 = ImageAsset(name: "duplicate-16")
    public static let duplicate24 = ImageAsset(name: "duplicate-24")
    public static let ellipsis16 = ImageAsset(name: "ellipsis-16")
    public static let eye16 = ImageAsset(name: "eye-16")
    public static let eye24 = ImageAsset(name: "eye-24")
    public static let eyeClosed16 = ImageAsset(name: "eye-closed-16")
    public static let eyeClosed24 = ImageAsset(name: "eye-closed-24")
    public static let feedDiscussion16 = ImageAsset(name: "feed-discussion-16")
    public static let feedForked16 = ImageAsset(name: "feed-forked-16")
    public static let feedHeart16 = ImageAsset(name: "feed-heart-16")
    public static let feedMerged16 = ImageAsset(name: "feed-merged-16")
    public static let feedPerson16 = ImageAsset(name: "feed-person-16")
    public static let feedRepo16 = ImageAsset(name: "feed-repo-16")
    public static let feedRocket16 = ImageAsset(name: "feed-rocket-16")
    public static let feedStar16 = ImageAsset(name: "feed-star-16")
    public static let feedTag16 = ImageAsset(name: "feed-tag-16")
    public static let feedTrophy16 = ImageAsset(name: "feed-trophy-16")
    public static let file16 = ImageAsset(name: "file-16")
    public static let file24 = ImageAsset(name: "file-24")
    public static let fileAdded16 = ImageAsset(name: "file-added-16")
    public static let fileBadge16 = ImageAsset(name: "file-badge-16")
    public static let fileBinary16 = ImageAsset(name: "file-binary-16")
    public static let fileBinary24 = ImageAsset(name: "file-binary-24")
    public static let fileCode16 = ImageAsset(name: "file-code-16")
    public static let fileCode24 = ImageAsset(name: "file-code-24")
    public static let fileDiff16 = ImageAsset(name: "file-diff-16")
    public static let fileDiff24 = ImageAsset(name: "file-diff-24")
    public static let fileDirectory16 = ImageAsset(name: "file-directory-16")
    public static let fileDirectory24 = ImageAsset(name: "file-directory-24")
    public static let fileDirectoryFill16 = ImageAsset(name: "file-directory-fill-16")
    public static let fileDirectoryFill24 = ImageAsset(name: "file-directory-fill-24")
    public static let fileDirectoryOpenFill16 = ImageAsset(name: "file-directory-open-fill-16")
    public static let fileDirectorySymlink16 = ImageAsset(name: "file-directory-symlink-16")
    public static let fileDirectorySymlink24 = ImageAsset(name: "file-directory-symlink-24")
    public static let fileMedia24 = ImageAsset(name: "file-media-24")
    public static let fileMoved16 = ImageAsset(name: "file-moved-16")
    public static let fileRemoved16 = ImageAsset(name: "file-removed-16")
    public static let fileSubmodule16 = ImageAsset(name: "file-submodule-16")
    public static let fileSubmodule24 = ImageAsset(name: "file-submodule-24")
    public static let fileSymlinkFile16 = ImageAsset(name: "file-symlink-file-16")
    public static let fileSymlinkFile24 = ImageAsset(name: "file-symlink-file-24")
    public static let fileZip16 = ImageAsset(name: "file-zip-16")
    public static let fileZip24 = ImageAsset(name: "file-zip-24")
    public static let filter16 = ImageAsset(name: "filter-16")
    public static let filter24 = ImageAsset(name: "filter-24")
    public static let fiscalHost16 = ImageAsset(name: "fiscal-host-16")
    public static let flame16 = ImageAsset(name: "flame-16")
    public static let flame24 = ImageAsset(name: "flame-24")
    public static let fold16 = ImageAsset(name: "fold-16")
    public static let fold24 = ImageAsset(name: "fold-24")
    public static let foldDown16 = ImageAsset(name: "fold-down-16")
    public static let foldDown24 = ImageAsset(name: "fold-down-24")
    public static let foldUp16 = ImageAsset(name: "fold-up-16")
    public static let foldUp24 = ImageAsset(name: "fold-up-24")
    public static let gear16 = ImageAsset(name: "gear-16")
    public static let gear24 = ImageAsset(name: "gear-24")
    public static let gift16 = ImageAsset(name: "gift-16")
    public static let gift24 = ImageAsset(name: "gift-24")
    public static let gitBranch16 = ImageAsset(name: "git-branch-16")
    public static let gitBranch24 = ImageAsset(name: "git-branch-24")
    public static let gitCommit16 = ImageAsset(name: "git-commit-16")
    public static let gitCommit24 = ImageAsset(name: "git-commit-24")
    public static let gitCompare16 = ImageAsset(name: "git-compare-16")
    public static let gitCompare24 = ImageAsset(name: "git-compare-24")
    public static let gitMerge16 = ImageAsset(name: "git-merge-16")
    public static let gitMerge24 = ImageAsset(name: "git-merge-24")
    public static let gitMergeQueue16 = ImageAsset(name: "git-merge-queue-16")
    public static let gitMergeQueue24 = ImageAsset(name: "git-merge-queue-24")
    public static let gitPullRequest16 = ImageAsset(name: "git-pull-request-16")
    public static let gitPullRequest24 = ImageAsset(name: "git-pull-request-24")
    public static let gitPullRequestClosed16 = ImageAsset(name: "git-pull-request-closed-16")
    public static let gitPullRequestClosed24 = ImageAsset(name: "git-pull-request-closed-24")
    public static let gitPullRequestDraft16 = ImageAsset(name: "git-pull-request-draft-16")
    public static let gitPullRequestDraft24 = ImageAsset(name: "git-pull-request-draft-24")
    public static let globe16 = ImageAsset(name: "globe-16")
    public static let globe24 = ImageAsset(name: "globe-24")
    public static let goal16 = ImageAsset(name: "goal-16")
    public static let goal24 = ImageAsset(name: "goal-24")
    public static let grabber16 = ImageAsset(name: "grabber-16")
    public static let grabber24 = ImageAsset(name: "grabber-24")
    public static let graph16 = ImageAsset(name: "graph-16")
    public static let graph24 = ImageAsset(name: "graph-24")
    public static let hash16 = ImageAsset(name: "hash-16")
    public static let hash24 = ImageAsset(name: "hash-24")
    public static let heading16 = ImageAsset(name: "heading-16")
    public static let heading24 = ImageAsset(name: "heading-24")
    public static let heart16 = ImageAsset(name: "heart-16")
    public static let heart24 = ImageAsset(name: "heart-24")
    public static let heartFill16 = ImageAsset(name: "heart-fill-16")
    public static let heartFill24 = ImageAsset(name: "heart-fill-24")
    public static let history16 = ImageAsset(name: "history-16")
    public static let history24 = ImageAsset(name: "history-24")
    public static let home16 = ImageAsset(name: "home-16")
    public static let home24 = ImageAsset(name: "home-24")
    public static let homeFill24 = ImageAsset(name: "home-fill-24")
    public static let horizontalRule16 = ImageAsset(name: "horizontal-rule-16")
    public static let horizontalRule24 = ImageAsset(name: "horizontal-rule-24")
    public static let hourglass16 = ImageAsset(name: "hourglass-16")
    public static let hourglass24 = ImageAsset(name: "hourglass-24")
    public static let hubot16 = ImageAsset(name: "hubot-16")
    public static let hubot24 = ImageAsset(name: "hubot-24")
    public static let idBadge16 = ImageAsset(name: "id-badge-16")
    public static let image16 = ImageAsset(name: "image-16")
    public static let image24 = ImageAsset(name: "image-24")
    public static let inbox16 = ImageAsset(name: "inbox-16")
    public static let inbox24 = ImageAsset(name: "inbox-24")
    public static let infinity16 = ImageAsset(name: "infinity-16")
    public static let infinity24 = ImageAsset(name: "infinity-24")
    public static let info16 = ImageAsset(name: "info-16")
    public static let info24 = ImageAsset(name: "info-24")
    public static let issueClosed16 = ImageAsset(name: "issue-closed-16")
    public static let issueClosed24 = ImageAsset(name: "issue-closed-24")
    public static let issueDraft16 = ImageAsset(name: "issue-draft-16")
    public static let issueDraft24 = ImageAsset(name: "issue-draft-24")
    public static let issueOpened16 = ImageAsset(name: "issue-opened-16")
    public static let issueOpened24 = ImageAsset(name: "issue-opened-24")
    public static let issueReopened16 = ImageAsset(name: "issue-reopened-16")
    public static let issueReopened24 = ImageAsset(name: "issue-reopened-24")
    public static let issueTrackedBy16 = ImageAsset(name: "issue-tracked-by-16")
    public static let issueTrackedBy24 = ImageAsset(name: "issue-tracked-by-24")
    public static let issueTracks16 = ImageAsset(name: "issue-tracks-16")
    public static let issueTracks24 = ImageAsset(name: "issue-tracks-24")
    public static let italic16 = ImageAsset(name: "italic-16")
    public static let italic24 = ImageAsset(name: "italic-24")
    public static let iterations16 = ImageAsset(name: "iterations-16")
    public static let iterations24 = ImageAsset(name: "iterations-24")
    public static let kebabHorizontal16 = ImageAsset(name: "kebab-horizontal-16")
    public static let kebabHorizontal24 = ImageAsset(name: "kebab-horizontal-24")
    public static let key16 = ImageAsset(name: "key-16")
    public static let key24 = ImageAsset(name: "key-24")
    public static let keyAsterisk16 = ImageAsset(name: "key-asterisk-16")
    public static let law16 = ImageAsset(name: "law-16")
    public static let law24 = ImageAsset(name: "law-24")
    public static let lightBulb16 = ImageAsset(name: "light-bulb-16")
    public static let lightBulb24 = ImageAsset(name: "light-bulb-24")
    public static let link16 = ImageAsset(name: "link-16")
    public static let link24 = ImageAsset(name: "link-24")
    public static let linkExternal16 = ImageAsset(name: "link-external-16")
    public static let linkExternal24 = ImageAsset(name: "link-external-24")
    public static let listOrdered16 = ImageAsset(name: "list-ordered-16")
    public static let listOrdered24 = ImageAsset(name: "list-ordered-24")
    public static let listUnordered16 = ImageAsset(name: "list-unordered-16")
    public static let listUnordered24 = ImageAsset(name: "list-unordered-24")
    public static let location16 = ImageAsset(name: "location-16")
    public static let location24 = ImageAsset(name: "location-24")
    public static let lock16 = ImageAsset(name: "lock-16")
    public static let lock24 = ImageAsset(name: "lock-24")
    public static let log16 = ImageAsset(name: "log-16")
    public static let log24 = ImageAsset(name: "log-24")
    public static let logoGist16 = ImageAsset(name: "logo-gist-16")
    public static let logoGithub16 = ImageAsset(name: "logo-github-16")
    public static let mail16 = ImageAsset(name: "mail-16")
    public static let mail24 = ImageAsset(name: "mail-24")
    public static let markGithub16 = ImageAsset(name: "mark-github-16")
    public static let markdown16 = ImageAsset(name: "markdown-16")
    public static let megaphone16 = ImageAsset(name: "megaphone-16")
    public static let megaphone24 = ImageAsset(name: "megaphone-24")
    public static let mention16 = ImageAsset(name: "mention-16")
    public static let mention24 = ImageAsset(name: "mention-24")
    public static let meter16 = ImageAsset(name: "meter-16")
    public static let milestone16 = ImageAsset(name: "milestone-16")
    public static let milestone24 = ImageAsset(name: "milestone-24")
    public static let mirror16 = ImageAsset(name: "mirror-16")
    public static let mirror24 = ImageAsset(name: "mirror-24")
    public static let moon16 = ImageAsset(name: "moon-16")
    public static let moon24 = ImageAsset(name: "moon-24")
    public static let mortarBoard16 = ImageAsset(name: "mortar-board-16")
    public static let mortarBoard24 = ImageAsset(name: "mortar-board-24")
    public static let moveToBottom16 = ImageAsset(name: "move-to-bottom-16")
    public static let moveToBottom24 = ImageAsset(name: "move-to-bottom-24")
    public static let moveToEnd16 = ImageAsset(name: "move-to-end-16")
    public static let moveToEnd24 = ImageAsset(name: "move-to-end-24")
    public static let moveToStart16 = ImageAsset(name: "move-to-start-16")
    public static let moveToStart24 = ImageAsset(name: "move-to-start-24")
    public static let moveToTop16 = ImageAsset(name: "move-to-top-16")
    public static let moveToTop24 = ImageAsset(name: "move-to-top-24")
    public static let multiSelect16 = ImageAsset(name: "multi-select-16")
    public static let multiSelect24 = ImageAsset(name: "multi-select-24")
    public static let mute16 = ImageAsset(name: "mute-16")
    public static let mute24 = ImageAsset(name: "mute-24")
    public static let noEntry16 = ImageAsset(name: "no-entry-16")
    public static let noEntry24 = ImageAsset(name: "no-entry-24")
    public static let noEntryFill12 = ImageAsset(name: "no-entry-fill-12")
    public static let northStar16 = ImageAsset(name: "north-star-16")
    public static let northStar24 = ImageAsset(name: "north-star-24")
    public static let note16 = ImageAsset(name: "note-16")
    public static let note24 = ImageAsset(name: "note-24")
    public static let number16 = ImageAsset(name: "number-16")
    public static let number24 = ImageAsset(name: "number-24")
    public static let organization16 = ImageAsset(name: "organization-16")
    public static let organization24 = ImageAsset(name: "organization-24")
    public static let package16 = ImageAsset(name: "package-16")
    public static let package24 = ImageAsset(name: "package-24")
    public static let packageDependencies16 = ImageAsset(name: "package-dependencies-16")
    public static let packageDependencies24 = ImageAsset(name: "package-dependencies-24")
    public static let packageDependents16 = ImageAsset(name: "package-dependents-16")
    public static let packageDependents24 = ImageAsset(name: "package-dependents-24")
    public static let paintbrush16 = ImageAsset(name: "paintbrush-16")
    public static let paperAirplane16 = ImageAsset(name: "paper-airplane-16")
    public static let paperAirplane24 = ImageAsset(name: "paper-airplane-24")
    public static let paperclip16 = ImageAsset(name: "paperclip-16")
    public static let paperclip24 = ImageAsset(name: "paperclip-24")
    public static let passkeyFill16 = ImageAsset(name: "passkey-fill-16")
    public static let passkeyFill24 = ImageAsset(name: "passkey-fill-24")
    public static let paste16 = ImageAsset(name: "paste-16")
    public static let paste24 = ImageAsset(name: "paste-24")
    public static let pencil16 = ImageAsset(name: "pencil-16")
    public static let pencil24 = ImageAsset(name: "pencil-24")
    public static let people16 = ImageAsset(name: "people-16")
    public static let people24 = ImageAsset(name: "people-24")
    public static let person16 = ImageAsset(name: "person-16")
    public static let person24 = ImageAsset(name: "person-24")
    public static let personAdd16 = ImageAsset(name: "person-add-16")
    public static let personAdd24 = ImageAsset(name: "person-add-24")
    public static let personFill16 = ImageAsset(name: "person-fill-16")
    public static let personFill24 = ImageAsset(name: "person-fill-24")
    public static let pin16 = ImageAsset(name: "pin-16")
    public static let pin24 = ImageAsset(name: "pin-24")
    public static let pinSlash16 = ImageAsset(name: "pin-slash-16")
    public static let pinSlash24 = ImageAsset(name: "pin-slash-24")
    public static let pivotColumn16 = ImageAsset(name: "pivot-column-16")
    public static let pivotColumn24 = ImageAsset(name: "pivot-column-24")
    public static let play16 = ImageAsset(name: "play-16")
    public static let play24 = ImageAsset(name: "play-24")
    public static let plug16 = ImageAsset(name: "plug-16")
    public static let plug24 = ImageAsset(name: "plug-24")
    public static let plus16 = ImageAsset(name: "plus-16")
    public static let plus24 = ImageAsset(name: "plus-24")
    public static let plusCircle16 = ImageAsset(name: "plus-circle-16")
    public static let plusCircle24 = ImageAsset(name: "plus-circle-24")
    public static let project16 = ImageAsset(name: "project-16")
    public static let project24 = ImageAsset(name: "project-24")
    public static let projectRoadmap16 = ImageAsset(name: "project-roadmap-16")
    public static let projectRoadmap24 = ImageAsset(name: "project-roadmap-24")
    public static let projectSymlink16 = ImageAsset(name: "project-symlink-16")
    public static let projectSymlink24 = ImageAsset(name: "project-symlink-24")
    public static let projectTemplate16 = ImageAsset(name: "project-template-16")
    public static let projectTemplate24 = ImageAsset(name: "project-template-24")
    public static let pulse16 = ImageAsset(name: "pulse-16")
    public static let pulse24 = ImageAsset(name: "pulse-24")
    public static let question16 = ImageAsset(name: "question-16")
    public static let question24 = ImageAsset(name: "question-24")
    public static let quote16 = ImageAsset(name: "quote-16")
    public static let quote24 = ImageAsset(name: "quote-24")
    public static let read16 = ImageAsset(name: "read-16")
    public static let read24 = ImageAsset(name: "read-24")
    public static let redo16 = ImageAsset(name: "redo-16")
    public static let relFilePath16 = ImageAsset(name: "rel-file-path-16")
    public static let relFilePath24 = ImageAsset(name: "rel-file-path-24")
    public static let reply16 = ImageAsset(name: "reply-16")
    public static let reply24 = ImageAsset(name: "reply-24")
    public static let repo16 = ImageAsset(name: "repo-16")
    public static let repo24 = ImageAsset(name: "repo-24")
    public static let repoClone16 = ImageAsset(name: "repo-clone-16")
    public static let repoClone24 = ImageAsset(name: "repo-clone-24")
    public static let repoDeleted16 = ImageAsset(name: "repo-deleted-16")
    public static let repoForked16 = ImageAsset(name: "repo-forked-16")
    public static let repoForked24 = ImageAsset(name: "repo-forked-24")
    public static let repoLocked16 = ImageAsset(name: "repo-locked-16")
    public static let repoLocked24 = ImageAsset(name: "repo-locked-24")
    public static let repoPull16 = ImageAsset(name: "repo-pull-16")
    public static let repoPull24 = ImageAsset(name: "repo-pull-24")
    public static let repoPush16 = ImageAsset(name: "repo-push-16")
    public static let repoPush24 = ImageAsset(name: "repo-push-24")
    public static let repoTemplate16 = ImageAsset(name: "repo-template-16")
    public static let repoTemplate24 = ImageAsset(name: "repo-template-24")
    public static let report16 = ImageAsset(name: "report-16")
    public static let report24 = ImageAsset(name: "report-24")
    public static let rocket16 = ImageAsset(name: "rocket-16")
    public static let rocket24 = ImageAsset(name: "rocket-24")
    public static let rows16 = ImageAsset(name: "rows-16")
    public static let rows24 = ImageAsset(name: "rows-24")
    public static let rss16 = ImageAsset(name: "rss-16")
    public static let rss24 = ImageAsset(name: "rss-24")
    public static let ruby16 = ImageAsset(name: "ruby-16")
    public static let ruby24 = ImageAsset(name: "ruby-24")
    public static let screenFull16 = ImageAsset(name: "screen-full-16")
    public static let screenFull24 = ImageAsset(name: "screen-full-24")
    public static let screenNormal16 = ImageAsset(name: "screen-normal-16")
    public static let screenNormal24 = ImageAsset(name: "screen-normal-24")
    public static let search16 = ImageAsset(name: "search-16")
    public static let search24 = ImageAsset(name: "search-24")
    public static let server16 = ImageAsset(name: "server-16")
    public static let server24 = ImageAsset(name: "server-24")
    public static let share16 = ImageAsset(name: "share-16")
    public static let share24 = ImageAsset(name: "share-24")
    public static let shareAndroid16 = ImageAsset(name: "share-android-16")
    public static let shareAndroid24 = ImageAsset(name: "share-android-24")
    public static let shield16 = ImageAsset(name: "shield-16")
    public static let shield24 = ImageAsset(name: "shield-24")
    public static let shieldCheck16 = ImageAsset(name: "shield-check-16")
    public static let shieldCheck24 = ImageAsset(name: "shield-check-24")
    public static let shieldLock16 = ImageAsset(name: "shield-lock-16")
    public static let shieldLock24 = ImageAsset(name: "shield-lock-24")
    public static let shieldSlash16 = ImageAsset(name: "shield-slash-16")
    public static let shieldSlash24 = ImageAsset(name: "shield-slash-24")
    public static let shieldX16 = ImageAsset(name: "shield-x-16")
    public static let shieldX24 = ImageAsset(name: "shield-x-24")
    public static let sidebarCollapse16 = ImageAsset(name: "sidebar-collapse-16")
    public static let sidebarCollapse24 = ImageAsset(name: "sidebar-collapse-24")
    public static let sidebarExpand16 = ImageAsset(name: "sidebar-expand-16")
    public static let sidebarExpand24 = ImageAsset(name: "sidebar-expand-24")
    public static let signIn16 = ImageAsset(name: "sign-in-16")
    public static let signIn24 = ImageAsset(name: "sign-in-24")
    public static let signOut16 = ImageAsset(name: "sign-out-16")
    public static let signOut24 = ImageAsset(name: "sign-out-24")
    public static let singleSelect16 = ImageAsset(name: "single-select-16")
    public static let singleSelect24 = ImageAsset(name: "single-select-24")
    public static let skip16 = ImageAsset(name: "skip-16")
    public static let skip24 = ImageAsset(name: "skip-24")
    public static let skipFill16 = ImageAsset(name: "skip-fill-16")
    public static let skipFill24 = ImageAsset(name: "skip-fill-24")
    public static let sliders16 = ImageAsset(name: "sliders-16")
    public static let smiley16 = ImageAsset(name: "smiley-16")
    public static let smiley24 = ImageAsset(name: "smiley-24")
    public static let sortAsc16 = ImageAsset(name: "sort-asc-16")
    public static let sortAsc24 = ImageAsset(name: "sort-asc-24")
    public static let sortDesc16 = ImageAsset(name: "sort-desc-16")
    public static let sortDesc24 = ImageAsset(name: "sort-desc-24")
    public static let sparkleFill16 = ImageAsset(name: "sparkle-fill-16")
    public static let sponsorTiers16 = ImageAsset(name: "sponsor-tiers-16")
    public static let sponsorTiers24 = ImageAsset(name: "sponsor-tiers-24")
    public static let square16 = ImageAsset(name: "square-16")
    public static let square24 = ImageAsset(name: "square-24")
    public static let squareFill16 = ImageAsset(name: "square-fill-16")
    public static let squareFill24 = ImageAsset(name: "square-fill-24")
    public static let squirrel16 = ImageAsset(name: "squirrel-16")
    public static let squirrel24 = ImageAsset(name: "squirrel-24")
    public static let stack16 = ImageAsset(name: "stack-16")
    public static let stack24 = ImageAsset(name: "stack-24")
    public static let star16 = ImageAsset(name: "star-16")
    public static let star24 = ImageAsset(name: "star-24")
    public static let starFill16 = ImageAsset(name: "star-fill-16")
    public static let starFill24 = ImageAsset(name: "star-fill-24")
    public static let stop16 = ImageAsset(name: "stop-16")
    public static let stop24 = ImageAsset(name: "stop-24")
    public static let stopwatch16 = ImageAsset(name: "stopwatch-16")
    public static let stopwatch24 = ImageAsset(name: "stopwatch-24")
    public static let strikethrough16 = ImageAsset(name: "strikethrough-16")
    public static let strikethrough24 = ImageAsset(name: "strikethrough-24")
    public static let sun16 = ImageAsset(name: "sun-16")
    public static let sun24 = ImageAsset(name: "sun-24")
    public static let sync16 = ImageAsset(name: "sync-16")
    public static let sync24 = ImageAsset(name: "sync-24")
    public static let tab24 = ImageAsset(name: "tab-24")
    public static let tabExternal16 = ImageAsset(name: "tab-external-16")
    public static let table16 = ImageAsset(name: "table-16")
    public static let table24 = ImageAsset(name: "table-24")
    public static let tag16 = ImageAsset(name: "tag-16")
    public static let tag24 = ImageAsset(name: "tag-24")
    public static let tasklist16 = ImageAsset(name: "tasklist-16")
    public static let tasklist24 = ImageAsset(name: "tasklist-24")
    public static let telescope16 = ImageAsset(name: "telescope-16")
    public static let telescope24 = ImageAsset(name: "telescope-24")
    public static let telescopeFill16 = ImageAsset(name: "telescope-fill-16")
    public static let telescopeFill24 = ImageAsset(name: "telescope-fill-24")
    public static let terminal16 = ImageAsset(name: "terminal-16")
    public static let terminal24 = ImageAsset(name: "terminal-24")
    public static let threeBars16 = ImageAsset(name: "three-bars-16")
    public static let thumbsdown16 = ImageAsset(name: "thumbsdown-16")
    public static let thumbsdown24 = ImageAsset(name: "thumbsdown-24")
    public static let thumbsup16 = ImageAsset(name: "thumbsup-16")
    public static let thumbsup24 = ImageAsset(name: "thumbsup-24")
    public static let tools16 = ImageAsset(name: "tools-16")
    public static let tools24 = ImageAsset(name: "tools-24")
    public static let trackedByClosedCompleted16 = ImageAsset(name: "tracked-by-closed-completed-16")
    public static let trackedByClosedCompleted24 = ImageAsset(name: "tracked-by-closed-completed-24")
    public static let trackedByClosedNotPlanned16 = ImageAsset(name: "tracked-by-closed-not-planned-16")
    public static let trackedByClosedNotPlanned24 = ImageAsset(name: "tracked-by-closed-not-planned-24")
    public static let trash16 = ImageAsset(name: "trash-16")
    public static let trash24 = ImageAsset(name: "trash-24")
    public static let triangleDown16 = ImageAsset(name: "triangle-down-16")
    public static let triangleDown24 = ImageAsset(name: "triangle-down-24")
    public static let triangleLeft16 = ImageAsset(name: "triangle-left-16")
    public static let triangleLeft24 = ImageAsset(name: "triangle-left-24")
    public static let triangleRight16 = ImageAsset(name: "triangle-right-16")
    public static let triangleRight24 = ImageAsset(name: "triangle-right-24")
    public static let triangleUp16 = ImageAsset(name: "triangle-up-16")
    public static let triangleUp24 = ImageAsset(name: "triangle-up-24")
    public static let trophy16 = ImageAsset(name: "trophy-16")
    public static let trophy24 = ImageAsset(name: "trophy-24")
    public static let typography16 = ImageAsset(name: "typography-16")
    public static let typography24 = ImageAsset(name: "typography-24")
    public static let undo16 = ImageAsset(name: "undo-16")
    public static let unfold16 = ImageAsset(name: "unfold-16")
    public static let unfold24 = ImageAsset(name: "unfold-24")
    public static let unlink16 = ImageAsset(name: "unlink-16")
    public static let unlink24 = ImageAsset(name: "unlink-24")
    public static let unlock16 = ImageAsset(name: "unlock-16")
    public static let unlock24 = ImageAsset(name: "unlock-24")
    public static let unmute16 = ImageAsset(name: "unmute-16")
    public static let unmute24 = ImageAsset(name: "unmute-24")
    public static let unread16 = ImageAsset(name: "unread-16")
    public static let unread24 = ImageAsset(name: "unread-24")
    public static let unverified16 = ImageAsset(name: "unverified-16")
    public static let unverified24 = ImageAsset(name: "unverified-24")
    public static let upload16 = ImageAsset(name: "upload-16")
    public static let upload24 = ImageAsset(name: "upload-24")
    public static let verified16 = ImageAsset(name: "verified-16")
    public static let verified24 = ImageAsset(name: "verified-24")
    public static let versions16 = ImageAsset(name: "versions-16")
    public static let versions24 = ImageAsset(name: "versions-24")
    public static let video16 = ImageAsset(name: "video-16")
    public static let video24 = ImageAsset(name: "video-24")
    public static let webhook16 = ImageAsset(name: "webhook-16")
    public static let workflow16 = ImageAsset(name: "workflow-16")
    public static let workflow24 = ImageAsset(name: "workflow-24")
    public static let x12 = ImageAsset(name: "x-12")
    public static let x16 = ImageAsset(name: "x-16")
    public static let x24 = ImageAsset(name: "x-24")
    public static let xCircle16 = ImageAsset(name: "x-circle-16")
    public static let xCircle24 = ImageAsset(name: "x-circle-24")
    public static let xCircleFill12 = ImageAsset(name: "x-circle-fill-12")
    public static let xCircleFill16 = ImageAsset(name: "x-circle-fill-16")
    public static let xCircleFill24 = ImageAsset(name: "x-circle-fill-24")
    public static let zap16 = ImageAsset(name: "zap-16")
    public static let zap24 = ImageAsset(name: "zap-24")
    public static let zoomIn16 = ImageAsset(name: "zoom-in-16")
    public static let zoomIn24 = ImageAsset(name: "zoom-in-24")
    public static let zoomOut16 = ImageAsset(name: "zoom-out-16")
    public static let zoomOut24 = ImageAsset(name: "zoom-out-24")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public final class ColorAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  public private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  public func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public private(set) lazy var swiftUIColor: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension SwiftUI.Color {
  init(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }
}
#endif

public struct ImageAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  public var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  public func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

public extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

public struct SymbolAsset {
  public fileprivate(set) var name: String

  #if os(iOS) || os(tvOS) || os(watchOS)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  public typealias Configuration = UIImage.SymbolConfiguration
  public typealias Image = UIImage

  @available(iOS 12.0, tvOS 12.0, watchOS 5.0, *)
  public var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load symbol asset named \(name).")
    }
    return result
  }

  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  public func image(with configuration: Configuration) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, with: configuration) else {
      fatalError("Unable to load symbol asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension SwiftUI.Image {
  init(asset: SymbolAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: SymbolAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: SymbolAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
