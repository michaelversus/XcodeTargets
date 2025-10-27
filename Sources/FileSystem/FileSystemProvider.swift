import Foundation

protocol FileSystemProvider {
    var currentDirectoryPath: String { get }
    func fileExists(atPath path: String) -> Bool
    func allFilePaths(in directoryPath: String) throws -> Set<String>
}
