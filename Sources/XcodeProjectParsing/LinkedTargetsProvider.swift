import XcodeProj
import Foundation

/// Provides access to native target names linked to a specific `PBXFileSystemSynchronizedRootGroup` within an Xcode project.
/// Use this provider to discover which targets reference a given synchronized root group.
struct LinkedTargetsProvider {
    /// The underlying Xcode project representation used for lookup.
    let proj: PBXProj

    /// Returns the unique names of native targets that are linked to the specified synchronized root group.
    /// - Parameter group: The file system synchronized root group whose linked targets should be discovered.
    /// - Returns: A set containing the names of all native targets linked to the provided group.
    func linkedTargets(group: PBXFileSystemSynchronizedRootGroup) -> Set<String> {
        let allTargets = proj.nativeTargets
        let groupTargets = allTargets.filter { target in
            target.fileSystemSynchronizedGroups?.contains(group) == true
        }.map(\.name)
        return Set(groupTargets)
    }
}
