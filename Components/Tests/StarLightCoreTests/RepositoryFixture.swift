import Foundation
import GitHubModels

/// `Repository` is a `MetaCodable`-generated final class with no memberwise initializer, so tests
/// build instances by round-tripping the bundled sample through JSON and patching the few fields
/// they actually care about.
enum RepositoryFixture {
    /// `description` and `topics` are always written, never left at the sample's own values, so a
    /// search test never matches through a field it did not set.
    static func make(
        fullname: String,
        description: String? = nil,
        topics: [String] = [],
        language: String? = nil,
        isPrivate: Bool = false,
        pushedAt: Date = Date(timeIntervalSince1970: 0)
    ) throws -> Repository {
        let encodedSample = try JSONEncoder().encode(Repository.testModel)
        guard var repositoryJSON = try JSONSerialization.jsonObject(with: encodedSample) as? [String: Any] else {
            throw RepositoryFixtureError.sampleIsNotAJSONObject
        }

        repositoryJSON["full_name"] = fullname
        repositoryJSON["name"] = String(fullname.split(separator: "/").last ?? "")
        repositoryJSON["description"] = description ?? NSNull()
        repositoryJSON["topics"] = topics
        repositoryJSON["language"] = language ?? NSNull()
        repositoryJSON["private"] = isPrivate
        repositoryJSON["pushed_at"] = ISO8601DateFormatter().string(from: pushedAt)

        let patchedData = try JSONSerialization.data(withJSONObject: repositoryJSON)
        return try JSONDecoder().decode(Repository.self, from: patchedData)
    }

    enum RepositoryFixtureError: Error {
        case sampleIsNotAJSONObject
    }
}
