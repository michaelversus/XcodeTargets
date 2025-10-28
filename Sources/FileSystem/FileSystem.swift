import Foundation

/// Provides file system related utilities backed by `FileManager`.
///
/// `FileSystem` is the concrete implementation of `FileSystemProvider` used to
/// query the current working directory, check file existence, and enumerate all
/// file paths contained within a directory.
///
/// Enumeration uses a lazily injected `enumeratorFactory` enabling testability
/// (a mock can be supplied) and flexibility (alternate enumeration strategies).
/// - Note: All returned file path sets use absolute URL string representations.
final class FileSystem: FileSystemProvider {
    private let fileManager: FileManager
    private let enumeratorFactory: (URL) -> FileManager.DirectoryEnumerator?

    /// The absolute path string of the current working directory.
    /// Mirrors `FileManager.currentDirectoryPath`.
    var currentDirectoryPath: String {
        fileManager.currentDirectoryPath
    }

    // MARK: - Initialization

    /// Creates a new `FileSystem` instance.
    /// - Parameters:
    ///   - fileManager: The `FileManager` used for low level file operations. Defaults to `.default`.
    ///   - enumeratorFactory: Closure producing a `FileManager.DirectoryEnumerator` for a directory URL. Injected for testability.
    init(
        fileManager: FileManager = .default,
        enumeratorFactory: @escaping (URL) -> FileManager.DirectoryEnumerator?
    ) {
        self.fileManager = fileManager
        self.enumeratorFactory = enumeratorFactory
    }

    // MARK: - File Queries

    /// Returns a set of absolute file URL string representations for all regular files contained in the directory tree.
    ///
    /// Directories are excluded. Hidden files are included if the underlying enumerator emits them.
    /// - Parameter directoryPath: Absolute or relative path to the directory whose contents should be enumerated.
    /// - Returns: A set of absolute URL strings for every non-directory file found beneath the provided path.
    /// - Throws: Propagates errors thrown during enumeration (currently none, retained for forward compatibility).
    func allFilePaths(in directoryPath: String) throws -> Set<String> {
        let directoryURL = URL(fileURLWithPath: directoryPath)
        let fileURLs = try allFiles(in: directoryURL)
        return Set(fileURLs.map { $0.absoluteString })
    }

    /// Returns a set of file URLs for all regular files under the provided directory URL.
    /// - Parameter directoryURL: The directory to enumerate.
    /// - Returns: A set of file URLs excluding directories.
    /// - Throws: Propagates errors thrown by the enumerator creation (currently none).
    /// - Important: If the enumerator cannot be created, an empty set is returned.
    func allFiles(in directoryURL: URL) throws -> Set<URL> {
        guard let enumerator = enumeratorFactory(directoryURL) else { return [] }
        return FileHandler.filterFiles(from: enumerator)
    }

    /// Indicates whether a file or directory exists at the specified path.
    /// - Parameter path: The path whose existence is being checked.
    /// - Returns: `true` if a file system item exists at the path; otherwise `false`.
    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
}
