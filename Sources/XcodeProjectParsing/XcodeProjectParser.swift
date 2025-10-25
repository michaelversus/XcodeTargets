import PathKit
import XcodeProj
import Foundation

struct XcodeProjectParser {
    private let fileManager: FileManagerProtocol
    private let configuration: Configuration
    private let vPrint: (String) -> Void

    init(
        fileManager: FileManagerProtocol,
        configuration: Configuration,
        vPrint: @escaping (String) -> Void
    ) {
        self.fileManager = fileManager
        self.configuration = configuration
        self.vPrint = vPrint
    }

    enum Error: Swift.Error, CustomStringConvertible, Equatable {
        case invalidTargetName(String)
        case invalidPath(String)
        case failedToResolveBuildableFolderPath(String)
        case forbiddenBuildableFoldersForGroups([String])
        case exceptionSetTargetIsNil(String)
        case exceptionSetTargetProductTypeIsNil(String)

        var description: String {
            switch self {
            case .invalidTargetName(let name):
                return "❌ Invalid target name \(name)"
            case .invalidPath(let path):
                return "❌ Invalid path \(path)"
            case .failedToResolveBuildableFolderPath(let path):
                return "❌ Failed to resolve buildable folder path \(path)"
            case .forbiddenBuildableFoldersForGroups(let groups):
                return "❌ Forbidden buildable folders for groups: \n\(groups.joined(separator: ", \n"))"
            case .exceptionSetTargetIsNil(let groupPath):
                return "❌ Exception set target is nil for group at path: \(groupPath)"
            case .exceptionSetTargetProductTypeIsNil(let groupPath):
                return "❌ Exception set target product type is nil for group at path: \(groupPath)"
            }
        }
    }

    func parseXcodeProject(at path: String, root: String) throws -> [String: TargetModel] {
        let projectPath = Path(path)
        let xcodeproj = try XcodeProj(path: projectPath)
        let targets = xcodeproj.pbxproj.nativeTargets
        var targetsIndex: [String: TargetModel] = [:]
        // parse targets
        for target in targets {
            vPrint("Target name: \(target.name)")
            let sourcefilePaths = try target.sourcesBuildPhase()?.files?.map { try $0.file?.fullPath(sourceRoot: root) ?? "" } ?? []
            if configuration.duplicatesValidationExcludedTargets?.contains(target.name) == false {
                try sourcefilePaths.duplicatesValidation(context: "Source File")
            }
            let resourceFilePaths = try target.resourcesBuildPhase()?.files?.map { file -> String in
                let fullPath = try file.file?.fullPath(sourceRoot: root) ?? ""
                // XcodeProj bug fix for .strings files the fullPath does not include the file name
                if let fileName = file.file?.name, fileName.contains(".strings") {
                    return fullPath + "/" + fileName
                } else {
                    return fullPath
                }
            } ?? []
            if configuration.duplicatesValidationExcludedTargets?.contains(target.name) == false {
                try resourceFilePaths.duplicatesValidation(context: "Resource")
            }
            let targetDependencies = target.dependencies.compactMap { $0.target?.name }
            if configuration.duplicatesValidationExcludedTargets?.contains(target.name) == false {
                try targetDependencies.duplicatesValidation(context: "Target Dependencies")
            }
            let frameworks = try target.frameworksBuildPhase()?.files?.map { $0.product?.productName ?? $0.file?.path ?? "" } ?? []
            if configuration.duplicatesValidationExcludedTargets?.contains(target.name) == false {
                try frameworks.duplicatesValidation(context: "Framework")
            }
            targetsIndex[target.name] = TargetModel(
                name: target.name,
                buildableFilePaths: [],
                sourceFilePaths: Set(sourcefilePaths),
                resourceFilePaths: Set(resourceFilePaths),
                dependencies: Set(targetDependencies),
                frameworks: Set(frameworks)
            )
        }
        // parse buildable folder files
        let fileSystemSynchronizedRootGroups = xcodeproj.pbxproj.fileSystemSynchronizedRootGroups
        for group in fileSystemSynchronizedRootGroups {
            guard let groupPath = try group.fullPath(sourceRoot: root) else {
                throw Error.failedToResolveBuildableFolderPath(group.path ?? "nil")
            }
            let linkedTargets = try group.linkedTargets(proj: xcodeproj.pbxproj)
            let groupFiles = try fileManager.allFiles(in: groupPath)
            var groupFilesIndex = linkedTargets.reduce([String: Set<String>]()) { result, targetName in
                var mutableResult = result
                mutableResult[targetName] = groupFiles
                return mutableResult
            }
            if let exceptions = group.exceptions, !exceptions.isEmpty {
                // handle exceptions
                vPrint("Group path with exceptions: \(groupPath), linked targets: \(linkedTargets)")
                for exception in exceptions {
                    if let exceptionSet = exception as? PBXFileSystemSynchronizedBuildFileExceptionSet {
                        guard let exceptionSetTarget = exceptionSet.target else {
                            throw Error.exceptionSetTargetIsNil(groupPath)
                        }
                        guard let exceptionSetTargetProductType = exceptionSetTarget.productType else {
                            throw Error.exceptionSetTargetProductTypeIsNil(groupPath)
                        }
                        vPrint("  - Exceptions: \(exceptionSet.membershipExceptions ?? []) target: \(exceptionSetTarget.name), targetType: \(exceptionSetTargetProductType.rawValue)")
                        for membershipException in exceptionSet.membershipExceptions ?? [] {
                            if exceptionSetTargetProductType != .unitTestBundle && exceptionSetTargetProductType != .uiTestBundle, let groupFilesSet = groupFilesIndex[exceptionSetTarget.name] {
                                // remove exceptions from group files for application targets
                                groupFilesIndex[exceptionSetTarget.name] = groupFilesSet.filter { !$0.contains(membershipException) }
                            } else if exceptionSetTargetProductType == .unitTestBundle || exceptionSetTargetProductType == .uiTestBundle {
                                // add exceptions for test targets
                                let groupFilesSet = groupFilesIndex[exceptionSetTarget.name] ?? []
                                let membershipExceptionPath = (groupPath as NSString).appendingPathComponent(membershipException)
                                groupFilesIndex[exceptionSetTarget.name] = groupFilesSet.union([membershipExceptionPath])
                            } else {
                                assertionFailure("Unexpected target type for group at path: \(groupPath), targetName: \(exceptionSetTarget.name), targetType: \(exceptionSetTargetProductType.rawValue)")
                            }
                        }
                    } else if let exceptionSet = exception as? PBXFileSystemSynchronizedGroupBuildPhaseMembershipExceptionSet {
                        vPrint("  - Exception: \(exceptionSet), no need to handle for now")
                    } else {
                        assertionFailure("Unexpected exception type for group at path: \(groupPath) exception type: \(type(of: exception))")
                        continue
                    }
                }
                // update targets index
                for (targetName, files) in groupFilesIndex {
                    targetsIndex.insert(buildableFilePaths: files, forTargets: [targetName])
                }
            } else {
                vPrint("Group path: \(groupPath), linked targets: \(linkedTargets)")
                vPrint("  - Buildable folder files count: \(groupFiles.count)")
                targetsIndex.insert(buildableFilePaths: groupFiles, forTargets: linkedTargets)
            }
        }
        targetsIndex.printSummary()
        return targetsIndex
    }
}
