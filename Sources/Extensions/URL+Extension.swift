import Foundation

// MARK: - Directory Inspection
extension URL {
    /// Determines whether the receiver represents an existing directory on disk.
    ///
    /// This queries the file system for the `.isDirectoryKey` resource value. The URL is
    /// expected to be a file URL. Non-file URLs or inaccessible resources will cause an error.
    /// Use this when you need a fidelity check instead of relying on path suffixes.
    ///
    /// - Returns: `true` when the URL points to a directory, otherwise `false`.
    /// - Throws: An error if the resource values cannot be retrieved (e.g. the URL is not a file URL
    ///           or the underlying file system returns an error).
    func isDirectory() throws -> Bool {
        try resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
    }
}
