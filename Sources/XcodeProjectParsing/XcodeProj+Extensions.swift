import XcodeProj
import Path

extension PBXProj {
    func validateFileSystemSynchronizedRootGroups(
        root: String,
        verbose: Bool,
        vPrint: @escaping (String) -> Void
    ) throws {
        let groupPathsWithTargets = try fileSystemSynchronizedRootGroupPathsWithTargets(
            root: root,
            verbose: verbose,
            vPrint: { print($0) }
        )
        let groupPathsWithoutTargets = groupPathsWithTargets.filter { _, targets in
            targets.isEmpty
        }
        guard groupPathsWithoutTargets.isEmpty else {
            throw XcodeProjectParser.Error.forbiddenBuildableFoldersForGroups(
                groupPathsWithoutTargets
                    .map { "\($0.key) (targets: \($0.value))" }
            )
        }
    }

    func fileSystemSynchronizedRootGroupPathsWithTargets(
        root: String,
        verbose: Bool,
        vPrint: @escaping (String) -> Void
    ) throws -> [String: Set<String>] {
        var groupPathsWithTargets: [String: Set<String>] = [:]
        for group in fileSystemSynchronizedRootGroups {
            guard let path = try group.fullPath(sourceRoot: root) else {
                throw XcodeProjectParser.Error.failedToResolveBuildableFolderPath(
                    group.path ?? "nil"
                )
            }
            let linkedTargets = try group.linkedTargets(proj: self)
            if verbose {
                vPrint("Targets: \(linkedTargets) for File System Synchronized Group at path: \(path)")
            }
            groupPathsWithTargets[path] = linkedTargets
        }
        return groupPathsWithTargets
    }
}
