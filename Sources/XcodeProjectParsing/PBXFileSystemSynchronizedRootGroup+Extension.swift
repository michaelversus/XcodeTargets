import XcodeProj
import PathKit
import Foundation

struct MembershipException: Hashable {
    let url: URL
    let isDirectory: Bool
}

extension PBXFileSystemSynchronizedRootGroup {
    func membershipExceptions(rootPath: String) throws -> Set<MembershipException> {
        Set(
            try (exceptions
                .map { $0.compactMap { $0 as? PBXFileSystemSynchronizedBuildFileExceptionSet } }
                .map { $0.compactMap(\.membershipExceptions).flatMap { $0 } } ?? [])
                .map {
                    var url = URL(fileURLWithPath: "\(rootPath)").appending(path: $0)
                    let isDirectory = try url.isDirectory()
                    if isDirectory {
                        url = URL(fileURLWithPath: "\(rootPath)").appending(path: "\($0)/")
                    }
                    return MembershipException(url: url, isDirectory: isDirectory)
                }
        )
    }

    func allValidfileURLs(
        root: String,
        fileManager: FileManagerProtocol
    ) throws -> Set<URL> {

        // Verify the directory exists
        guard fileManager.fileExists(atPath: root) else {
            throw XcodeProjectParser.Error.invalidPath(root)
        }

        let exceptions = try membershipExceptions(rootPath: root)
        let rootURL = URL(fileURLWithPath: root)
        return try fileManager.allFiles(in: rootURL, membershipExceptions: exceptions)
    }

    func linkedTargets(
        proj: PBXProj
    ) throws -> Set<String> {
        let allTargets = proj.nativeTargets
        let groupTargets = allTargets.filter { target in
            target.fileSystemSynchronizedGroups?.contains(self) == true
        }.map(\.name)
        return Set(groupTargets)
    }
}
