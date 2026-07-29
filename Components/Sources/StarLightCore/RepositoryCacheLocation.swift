import Foundation

/// Resolves where the repository services keep their JSON caches, and migrates caches written
/// under an older file name so that renaming one never costs the user a full refresh.
enum RepositoryCacheLocation {
    static func storageURL(forFileNamed fileName: String) -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appending(path: fileName)
    }

    static func migrateLegacyStorage(from legacyFileName: String, to currentFileName: String) {
        let fileManager = FileManager.default
        let currentURL = storageURL(forFileNamed: currentFileName)
        let legacyURL = storageURL(forFileNamed: legacyFileName)

        guard !fileManager.fileExists(atPath: currentURL.path),
              fileManager.fileExists(atPath: legacyURL.path) else {
            return
        }

        try? fileManager.moveItem(at: legacyURL, to: currentURL)
    }
}
