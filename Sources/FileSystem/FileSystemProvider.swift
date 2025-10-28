import Foundation

/// Abstraction defining minimal file system query capabilities.
///
/// Conforming types provide access to the current working directory path, existence checks, and
/// recursive enumeration of all regular file paths under a given directory path.
/// - Note: Returned file path collections use absolute URL string representations for consistency.
protocol FileSystemProvider {
    /// The absolute path string of the current working directory.
    var currentDirectoryPath: String { get }

    /// Indicates whether a file or directory exists at the specified path.
    /// - Parameter path: A file or directory path (absolute or relative).
    /// - Returns: `true` if an item exists at the path; otherwise `false`.
    func fileExists(atPath path: String) -> Bool

    /// Returns a set of absolute file URL string representations for all regular files contained
    /// within the directory tree rooted at the provided path.
    /// - Parameter directoryPath: Path to the directory whose contents should be recursively enumerated.
    /// - Returns: A set of absolute URL strings for each non-directory file discovered.
    /// - Throws: Implementation-defined errors during enumeration.
    func allFilePaths(in directoryPath: String) throws -> Set<String>
}
