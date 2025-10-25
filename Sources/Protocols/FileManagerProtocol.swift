import Foundation

protocol FileManagerProtocol {
    var currentDirectoryPath: String { get }
    func fileExists(atPath path: String) -> Bool
    func allFiles(in directoryPath: String) throws -> Set<String>
    func allFiles(in directoryURL: URL, membershipExceptions: Set<MembershipException>) throws -> Set<URL>
}

extension FileManager: FileManagerProtocol {
    func allFiles(in directoryURL: URL, membershipExceptions: Set<MembershipException>) throws -> Set<URL> {
        let enumerator = enumerator(
            at: directoryURL,
            includingPropertiesForKeys: nil
        )
        let directoryExceptionsURLs = membershipExceptions.filter { $0.isDirectory }.map(\.url)
        let fileExceptionsURLs = membershipExceptions.filter { !$0.isDirectory }.map(\.url)
        var fileURLs = [URL]()
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.hasDirectoryPath {
                if directoryExceptionsURLs.contains(fileURL) {
                    enumerator?.skipDescendants()
                    continue
                } else {
                    continue
                }
            } else {
                if fileExceptionsURLs.contains(fileURL) {
                    continue
                } else {
                    fileURLs.append(fileURL)
                }
            }
            fileURLs.append(fileURL)
        }
        return Set(fileURLs)
    }
}

extension FileManager {
    func allFiles(in directoryPath: String) throws -> Set<String> {
        let directoryURL = URL(fileURLWithPath: directoryPath)
        let fileURLs = try allFiles(in: directoryURL)
        return Set(fileURLs.map { $0.absoluteString })
    }

    func allFiles(in directoryURL: URL) throws -> Set<URL> {
        let enumerator = enumerator(
            at: directoryURL,
            includingPropertiesForKeys: nil
        )
        var fileURLs = [URL]()
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.hasDirectoryPath {
                continue
            } else {
                fileURLs.append(fileURL)
            }
        }
        return Set(fileURLs)
    }
}
