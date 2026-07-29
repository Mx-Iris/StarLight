import Foundation
import GitHubModels

/// Combines the two repository collections into the single list the quick action bar searches.
///
/// Matching and ranking live in `RepositorySearchIndex`; the free functions here are the shared
/// text splitting both sides depend on.
public enum RepositorySearchCatalog {
    /// Personal repositories come first: a repository you own or work on is a more likely target
    /// than one you starred years ago, and equally good matches keep the order they are given in.
    ///
    /// A repository can appear in both collections — starring your own work is common — so entries
    /// are deduplicated by full name, keeping the first occurrence.
    ///
    /// `includingPrivateRepositories` is what the Settings toggle controls. Turning it off hides
    /// private repositories immediately, even while the token still carries the `repo` scope and
    /// the caches still hold them; revoking the grant itself is done on GitHub.
    public static func merged(
        personalRepositories: [Repository],
        starredRepositories: [Repository],
        includingPrivateRepositories: Bool
    ) -> [Repository] {
        var seenFullnames: Set<String> = []
        var mergedRepositories: [Repository] = []
        mergedRepositories.reserveCapacity(personalRepositories.count + starredRepositories.count)

        for repository in personalRepositories + starredRepositories {
            guard includingPrivateRepositories || !repository.isPrivate else { continue }
            guard seenFullnames.insert(repository.fullname).inserted else { continue }
            mergedRepositories.append(repository)
        }

        return mergedRepositories
    }

    /// Splits arbitrary prose on whitespace and punctuation, lowercasing each word.
    static func searchWords(in text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }

    /// Splits a repository name or topic the way the name field is indexed: on punctuation *and* on
    /// camel-case humps, so `OpenMissionControl` is reachable by `mission` and `CLIProxyAPI` by
    /// `proxy`.
    static func searchableWords(inRepositoryName name: String) -> [String] {
        name.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .flatMap { camelCaseWords(in: $0) }
            .map { $0.lowercased() }
    }

    /// Splits one punctuation-free segment on camel-case boundaries.
    ///
    /// Two kinds of boundary exist: a capital following a non-capital starts a new word
    /// (`OpenMission` → `Open`, `Mission`), and a lowercase letter following a run of capitals means
    /// the last capital belonged to the new word, not the acronym (`CLIProxy` → `CLI`, `Proxy`).
    private static func camelCaseWords(in segment: Substring) -> [Substring] {
        var words: [Substring] = []
        var currentWordStart = segment.startIndex
        var previousCharacter: Character?

        for characterIndex in segment.indices {
            let character = segment[characterIndex]
            defer { previousCharacter = character }

            guard let previousCharacter, characterIndex > currentWordStart else { continue }

            if character.isUppercase, !previousCharacter.isUppercase {
                words.append(segment[currentWordStart ..< characterIndex])
                currentWordStart = characterIndex
            } else if character.isLowercase, previousCharacter.isUppercase {
                let acronymEnd = segment.index(before: characterIndex)
                guard acronymEnd > currentWordStart else { continue }
                words.append(segment[currentWordStart ..< acronymEnd])
                currentWordStart = acronymEnd
            }
        }

        words.append(segment[currentWordStart...])
        return words
    }
}

/// A repository list with every searchable field already split into words, so that typing does not
/// re-tokenize the whole collection on every keystroke.
///
/// The rules mirror what GitHub's own "Search stars" box does, verified against a live account:
///
/// - Only three fields are searched — repository name, description, and topics. The owner login,
///   the language, and the README are *not* searched. Matching on the owner was tried and dropped
///   deliberately: owner logins are rarely remembered accurately enough to type.
/// - The name is matched by prefix, either against the whole name or against any word inside it,
///   where words are split on punctuation and camel-case humps. `board` therefore finds
///   `BulletinBoard` but not `Mac-Finder-Clipboard`.
/// - Description and topics are matched by whole word. `clip` therefore does *not* find a
///   repository merely described as a "clipboard manager".
/// - Every whitespace-separated word in the query must match, though different words may match
///   through different fields.
public struct RepositorySearchIndex {
    private let indexedRepositories: [IndexedRepository]

    public init(repositories: [Repository]) {
        indexedRepositories = repositories.map(IndexedRepository.init)
    }

    /// Whether there is anything to search — false before either cache has loaded.
    public var isEmpty: Bool { indexedRepositories.isEmpty }

    /// The repositories matching `searchTerm`, strongest match first.
    ///
    /// Ties keep the indexed order, which is what makes the ranking safe to apply to an already
    /// meaningful list: equally good name matches stay in "your own repositories first, then most
    /// recently starred" order rather than being reshuffled arbitrarily.
    public func search(matching searchTerm: String) -> [Repository] {
        let queryWords = RepositorySearchCatalog.searchWords(in: searchTerm)
        guard !queryWords.isEmpty else { return [] }

        var rankedMatches: [RankedMatch] = []

        for (indexedPosition, indexedRepository) in indexedRepositories.enumerated() {
            guard let relevance = indexedRepository.relevance(forQueryWords: queryWords) else { continue }
            rankedMatches.append(
                RankedMatch(
                    repository: indexedRepository.repository,
                    relevance: relevance,
                    indexedPosition: indexedPosition
                )
            )
        }

        rankedMatches.sort { leftMatch, rightMatch in
            if leftMatch.relevance != rightMatch.relevance {
                return leftMatch.relevance > rightMatch.relevance
            }
            return leftMatch.indexedPosition < rightMatch.indexedPosition
        }

        return rankedMatches.map(\.repository)
    }

    /// Whether a single repository matches `searchTerm` at all, ignoring how strongly. Indexing one
    /// repository for one question is wasteful, so this exists for tests and one-off checks rather
    /// than for the typing path.
    public static func repository(_ repository: Repository, matches searchTerm: String) -> Bool {
        let queryWords = RepositorySearchCatalog.searchWords(in: searchTerm)
        guard !queryWords.isEmpty else { return false }
        return IndexedRepository(repository).relevance(forQueryWords: queryWords) != nil
    }

    private struct RankedMatch {
        let repository: Repository
        let relevance: Int
        let indexedPosition: Int
    }

    private struct IndexedRepository {
        let repository: Repository
        let lowercasedName: String
        let nameWords: [String]
        let topicWords: [String]
        let descriptionWords: [String]

        init(_ repository: Repository) {
            self.repository = repository
            lowercasedName = repository.name.lowercased()
            nameWords = RepositorySearchCatalog.searchableWords(inRepositoryName: repository.name)
            topicWords = repository.topics.flatMap(RepositorySearchCatalog.searchableWords(inRepositoryName:))
            descriptionWords = RepositorySearchCatalog.searchWords(in: repository.description ?? "")
        }

        /// The summed relevance of every query word, or `nil` when any single word matches nothing —
        /// the query is an AND across words.
        func relevance(forQueryWords queryWords: [String]) -> Int? {
            var totalRelevance = 0

            for queryWord in queryWords {
                if lowercasedName == queryWord {
                    totalRelevance += FieldRelevance.exactName
                } else if lowercasedName.hasPrefix(queryWord) {
                    totalRelevance += FieldRelevance.namePrefix
                } else if nameWords.contains(where: { $0.hasPrefix(queryWord) }) {
                    totalRelevance += FieldRelevance.nameWordPrefix
                } else if topicWords.contains(where: { $0.matchesWholeWord(queryWord) }) {
                    totalRelevance += FieldRelevance.topic
                } else if descriptionWords.contains(where: { $0.matchesWholeWord(queryWord) }) {
                    totalRelevance += FieldRelevance.description
                } else {
                    return nil
                }
            }

            return totalRelevance
        }
    }

    /// How strongly a single query word can match, in descending order of confidence. The raw
    /// values are what gets summed across query words, so the gaps between them matter more than
    /// the numbers themselves: a name hit must always outweigh a description hit.
    private enum FieldRelevance {
        static let exactName = 100
        static let namePrefix = 80
        static let nameWordPrefix = 60
        static let topic = 40
        static let description = 20
    }
}

private extension String {
    /// Description and topic words match the query whole, not by prefix — that is what keeps `clip`
    /// from dragging in every repository described as a "clipboard manager".
    ///
    /// Languages written without spaces are the deliberate exception. A Chinese description is one
    /// unbroken run of characters to any whitespace-based tokenizer, so whole-word matching would
    /// make it unsearchable; those queries fall back to substring matching. GitHub reaches the same
    /// outcome with a CJK-aware analyzer, which is more than this local search needs.
    func matchesWholeWord(_ queryWord: String) -> Bool {
        if queryWord.contains(where: \.isWrittenWithoutWordBreaks) {
            return contains(queryWord)
        }
        return self == queryWord
    }
}

private extension Character {
    /// Scripts that do not separate words with spaces, and so cannot be tokenized into words the
    /// way Latin text can. Covers the CJK ranges plus Japanese kana.
    var isWrittenWithoutWordBreaks: Bool {
        unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3040...0x30FF, // Hiragana and Katakana
                 0x3400...0x4DBF, // CJK Unified Ideographs Extension A
                 0x4E00...0x9FFF, // CJK Unified Ideographs
                 0xF900...0xFAFF, // CJK Compatibility Ideographs
                 0x20000...0x2FA1F: // CJK Unified Ideographs Extensions B onwards
                true
            default:
                false
            }
        }
    }
}
