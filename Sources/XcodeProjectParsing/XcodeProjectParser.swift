import PathKit
import XcodeProj
import Foundation

struct XcodeProjectParser {

    enum Error: Swift.Error, CustomStringConvertible, Equatable {
        case invalidTargetName(String)
        case invalidPath(String)

        var description: String {
            switch self {
            case .invalidTargetName(let name):
                return "❌ Invalid target name \(name)"
            case .invalidPath(let path):
                return "❌ Invalid path \(path)"
            }
        }
    }

    func parseXcodeProjectTarget(
        at path: String,
        targetName: String,
        root: String,
        verbose: Bool
    ) throws -> Target {
        let projectPath = Path(path)
        let xcodeproj = try XcodeProj(path: projectPath)
        guard let target = xcodeproj.pbxproj.targets(named: targetName).first else {  throw Error.invalidTargetName(targetName) }
        let filePaths = try target.sourcesBuildPhase()?.files?.map { try $0.file?.fullPath(sourceRoot: root) ?? "" } ?? []
        let resources = try target.resourcesBuildPhase()?.files?.map { try $0.file?.fullPath(sourceRoot: root) ?? "" } ?? []
        var buildableFolderFiles: [String] = []
        if let fileSystemSynchronizedGroups = target.fileSystemSynchronizedGroups {
            for fileSystemSynchronizedGroup in fileSystemSynchronizedGroups {
                if let fullPath = try fileSystemSynchronizedGroup.fullPath(sourceRoot: root) {
                    debugPrint("File System Synchronized Group at path: \(fullPath)")
                    let membershipExceptions = try fileSystemSynchronizedGroup.membershipExceptions(rootPath: fullPath)
                    if !membershipExceptions.isEmpty {
                        //debugPrint("Membership Exceptions: \(membershipExceptions.map(\.url.absoluteString))")
                    }
                    let allValidFiles = try fileSystemSynchronizedGroup.allValidfileURLs(
                        root: fullPath,
                        fileManager: FileManager.default
                    )
                    buildableFolderFiles.append(contentsOf: allValidFiles.map { $0.absoluteString })
                }
            }
        }
        return Target(
            name: targetName,
            filePaths: Set(filePaths + resources + buildableFolderFiles)
        )
    }
}
