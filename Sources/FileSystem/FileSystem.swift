import Foundation

final class FileSystem: FileSystemProvider {
    private let fileManager: FileManager
    private let enumeratorFactory: (URL) -> FileManager.DirectoryEnumerator?

    var currentDirectoryPath: String {
        fileManager.currentDirectoryPath
    }

    init(
        fileManager: FileManager = .default,
        enumeratorFactory: @escaping (URL) -> FileManager.DirectoryEnumerator?
    ) {
        self.fileManager = fileManager
        self.enumeratorFactory = enumeratorFactory
    }

    func allFilePaths(in directoryPath: String) throws -> Set<String> {
        let directoryURL = URL(fileURLWithPath: directoryPath)
        let fileURLs = try allFiles(in: directoryURL)
        return Set(fileURLs.map { $0.absoluteString })
    }

    func allFiles(in directoryURL: URL) throws -> Set<URL> {
        guard let enumerator = enumeratorFactory(directoryURL) else { return [] }
        return FileHandler.filterFiles(from: enumerator)
    }

    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
}
