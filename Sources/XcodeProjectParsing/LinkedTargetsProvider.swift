import XcodeProj
import Foundation

struct LinkedTargetsProvider {
    let group: PBXFileSystemSynchronizedRootGroup
    let proj: PBXProj

    func linkedTargets() -> Set<String> {
        let allTargets = proj.nativeTargets
        let groupTargets = allTargets.filter { target in
            target.fileSystemSynchronizedGroups?.contains(group) == true
        }.map(\.name)
        return Set(groupTargets)
    }
}

