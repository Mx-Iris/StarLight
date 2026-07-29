import Foundation
import Testing
import GitHubModels
@testable import StarLightCore

struct RepositorySearchCatalogTests {
    @Test
    func putsPersonalRepositoriesBeforeStarredRepositories() throws {
        let merged = RepositorySearchCatalog.merged(
            personalRepositories: [try RepositoryFixture.make(fullname: "me/mine")],
            starredRepositories: [try RepositoryFixture.make(fullname: "someone/starred")],
            includingPrivateRepositories: true
        )

        #expect(merged.map(\.fullname) == ["me/mine", "someone/starred"])
    }

    @Test
    func dropsARepositoryThatIsBothOwnedAndStarred() throws {
        let merged = RepositorySearchCatalog.merged(
            personalRepositories: [try RepositoryFixture.make(fullname: "me/mine")],
            starredRepositories: [try RepositoryFixture.make(fullname: "me/mine")],
            includingPrivateRepositories: true
        )

        #expect(merged.map(\.fullname) == ["me/mine"])
    }

    @Test
    func hidesPrivateRepositoriesWhenTheSettingIsOff() throws {
        let merged = RepositorySearchCatalog.merged(
            personalRepositories: [
                try RepositoryFixture.make(fullname: "me/secret", isPrivate: true),
                try RepositoryFixture.make(fullname: "me/open"),
            ],
            starredRepositories: [],
            includingPrivateRepositories: false
        )

        #expect(merged.map(\.fullname) == ["me/open"])
    }

    @Test
    func keepsPrivateRepositoriesWhenTheSettingIsOn() throws {
        let merged = RepositorySearchCatalog.merged(
            personalRepositories: [try RepositoryFixture.make(fullname: "me/secret", isPrivate: true)],
            starredRepositories: [],
            includingPrivateRepositories: true
        )

        #expect(merged.map(\.fullname) == ["me/secret"])
    }

    // MARK: - Name matching

    @Test
    func matchesTheStartOfTheName() throws {
        let repository = try RepositoryFixture.make(fullname: "Clipy/Clipy")
        #expect(RepositorySearchIndex.repository(repository, matches: "clip"))
        #expect(RepositorySearchIndex.repository(repository, matches: "clipy"))
    }

    @Test
    func matchesTheStartOfAWordInsideTheName() throws {
        let clipboard = try RepositoryFixture.make(fullname: "Wcowin/Mac-Finder-Clipboard")
        #expect(RepositorySearchIndex.repository(clipboard, matches: "clip"))
        #expect(RepositorySearchIndex.repository(clipboard, matches: "finder"))

        let missionControl = try RepositoryFixture.make(fullname: "nohackjustnoobb/OpenMissionControl")
        #expect(RepositorySearchIndex.repository(missionControl, matches: "missio"))
    }

    @Test
    func doesNotMatchTheMiddleOfAWordInTheName() throws {
        let clipboard = try RepositoryFixture.make(fullname: "Wcowin/Mac-Finder-Clipboard")
        #expect(!RepositorySearchIndex.repository(clipboard, matches: "board"))

        let bulletinBoard = try RepositoryFixture.make(fullname: "alexaubry/BulletinBoard")
        #expect(RepositorySearchIndex.repository(bulletinBoard, matches: "board"))
    }

    @Test
    func splitsAnAcronymFromTheWordFollowingIt() throws {
        let repository = try RepositoryFixture.make(fullname: "router-for-me/CLIProxyAPI")
        #expect(RepositorySearchIndex.repository(repository, matches: "proxy"))
        #expect(RepositorySearchIndex.repository(repository, matches: "api"))
        #expect(RepositorySearchIndex.repository(repository, matches: "clip"))
    }

    // MARK: - Description and topic matching

    @Test
    func matchesDescriptionAndTopicsByWholeWordOnly() throws {
        let repository = try RepositoryFixture.make(
            fullname: "abue-ammar/tinycast",
            description: "a tiny macOS launcher with clipboard history",
            topics: ["menu-bar"]
        )

        #expect(RepositorySearchIndex.repository(repository, matches: "clipboard"))
        #expect(RepositorySearchIndex.repository(repository, matches: "menu"))
        #expect(!RepositorySearchIndex.repository(repository, matches: "clip"))
    }

    @Test
    func matchesLanguagesWrittenWithoutSpacesBySubstring() throws {
        let repository = try RepositoryFixture.make(
            fullname: "SkyBlue997/enableMacosAI",
            description: "国行 Mac 一键开启完整 Apple 智能"
        )

        #expect(RepositorySearchIndex.repository(repository, matches: "一键"))
        #expect(!RepositorySearchIndex.repository(repository, matches: "关闭"))
    }

    // MARK: - Fields that are deliberately not searched

    @Test
    func doesNotMatchTheOwner() throws {
        let repository = try RepositoryFixture.make(fullname: "sindresorhus/Pasteboard-Viewer")
        #expect(!RepositorySearchIndex.repository(repository, matches: "sindresorhus"))
        #expect(RepositorySearchIndex.repository(repository, matches: "pasteboard"))
    }

    @Test
    func doesNotMatchTheLanguage() throws {
        let repository = try RepositoryFixture.make(fullname: "someone/notes", language: "Makefile")
        #expect(!RepositorySearchIndex.repository(repository, matches: "makefile"))
    }

    // MARK: - Query semantics

    @Test
    func requiresEveryWordToMatch() throws {
        let repository = try RepositoryFixture.make(
            fullname: "Clipy/Clipy",
            description: "clipboard extension app for macOS",
            topics: ["swift"]
        )

        #expect(RepositorySearchIndex.repository(repository, matches: "clip swift"))
        #expect(!RepositorySearchIndex.repository(repository, matches: "clip nonexistentword"))
    }

    @Test
    func rejectsAnEmptySearchTerm() throws {
        let repository = try RepositoryFixture.make(fullname: "octocat/spoon-knife")
        #expect(!RepositorySearchIndex.repository(repository, matches: ""))
        #expect(RepositorySearchIndex(repositories: [repository]).search(matching: "   ").isEmpty)
    }

    // MARK: - Ranking

    @Test
    func ranksNameMatchesAboveDescriptionMatches() throws {
        let repositories = [
            try RepositoryFixture.make(fullname: "someone/notes", description: "a clipboard manager"),
            try RepositoryFixture.make(fullname: "someone/clipboard-tools", topics: ["clipboard"]),
            try RepositoryFixture.make(fullname: "someone/clipboard"),
        ]

        let results = RepositorySearchIndex(repositories: repositories).search(matching: "clipboard")

        #expect(results.map(\.name) == ["clipboard", "clipboard-tools", "notes"])
    }

    @Test
    func keepsTheIncomingOrderForEquallyStrongMatches() throws {
        let repositories = [
            try RepositoryFixture.make(fullname: "someone/clip-one"),
            try RepositoryFixture.make(fullname: "someone/clip-two"),
            try RepositoryFixture.make(fullname: "someone/clip-three"),
        ]

        let results = RepositorySearchIndex(repositories: repositories).search(matching: "clip")

        #expect(results.map(\.name) == ["clip-one", "clip-two", "clip-three"])
    }

    @Test
    func dropsRepositoriesThatDoNotMatch() throws {
        let repositories = [
            try RepositoryFixture.make(fullname: "someone/clipboard"),
            try RepositoryFixture.make(fullname: "someone/unrelated"),
        ]

        let results = RepositorySearchIndex(repositories: repositories).search(matching: "clipboard")

        #expect(results.map(\.name) == ["clipboard"])
    }
}
