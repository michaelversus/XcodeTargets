import XcodeProj

extension PBXTarget {
    func buildableFoldersFilePaths(
        root: String,
        fileManager: FileManagerProtocol
    ) throws -> [String] {
        guard let fileSystemSynchronizedGroups = fileSystemSynchronizedGroups else { return [] }
        var buildableFolderFiles: [String] = []
        for group in fileSystemSynchronizedGroups {
            guard let fullPath = try group.fullPath(sourceRoot: root) else { continue }
            let allValidFiles = try group.allValidfileURLs(
                root: fullPath,
                fileManager: fileManager
            )
            for file in allValidFiles {
                debugPrint("  - Buildable folder file: \(file.path)")
            }
            buildableFolderFiles.append(contentsOf: allValidFiles.map { $0.absoluteString })
        }
        return buildableFolderFiles
    }
}
