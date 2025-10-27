import XcodeProj
import Foundation

extension PBXFileSystemSynchronizedRootGroup {
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
