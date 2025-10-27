import Foundation

extension URL {
    func isDirectory() throws -> Bool {
        try resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
    }
}
