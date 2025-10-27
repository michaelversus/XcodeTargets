import Foundation

enum FileHandler {
    static func filterFiles(
        from enumerator: FileManager.DirectoryEnumerator
    ) -> Set<URL> {
        var fileURLs = [URL]()
        while let fileURL = enumerator.nextObject() as? URL {
            if fileURL.hasDirectoryPath {
                continue
            } else {
                fileURLs.append(fileURL)
            }
        }
        return Set(fileURLs)
    }
}
