import PathKit
import XcodeProj
import Foundation

struct XcodeProjectParser {
    private let fileSystem: FileSystemProvider
    private let configuration: Configuration
    private let print: (String) -> Void
    private let vPrint: (String) -> Void
    private let linkedTargetsProviderFactory: (PBXFileSystemSynchronizedRootGroup, PBXProj) -> Set<String>

    init(
        fileSystem: FileSystemProvider,
        configuration: Configuration,
        print: @escaping (String) -> Void,
        vPrint: @escaping (String) -> Void,
        linkedTargetsProviderFactory: @escaping (PBXFileSystemSynchronizedRootGroup, PBXProj) -> Set<String>
    ) {
        self.fileSystem = fileSystem
        self.configuration = configuration
        self.print = print
        self.vPrint = vPrint
        self.linkedTargetsProviderFactory = linkedTargetsProviderFactory
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

    func parseXcodeProject(
        at path: String,
        root: String
    ) throws -> [String: TargetModel] {
        let xcodeproj = try makeProject(at: path)
        print("Parsing Xcode project at path: \(path)")
        var targetsIndex: [String: TargetModel] = try parseTargets(
            proj: xcodeproj,
            root: root
        )
        try parseSynchronizedRootGroups(
            proj: xcodeproj,
            root: root,
            targetsIndex: &targetsIndex
        )
        targetsIndex.printSummary(
            print: print,
            vPrint: vPrint
        )
        return targetsIndex
    }
}

private extension XcodeProjectParser {
    func makeProject(at path: String) throws -> XcodeProj {
        let projectPath = Path(path)
        return try XcodeProj(path: projectPath)
    }
    func parseTargets(
        proj: XcodeProj,
        root: String
    ) throws -> [String: TargetModel] {
        var index: [String: TargetModel] = [:]
        for target in proj.pbxproj.nativeTargets {
            print("Parsing Target: \(target.name)")
            let sourceFilePaths = try extractReferencedSourceFiles(
                target: target,
                root: root
            )
            try validateDuplicatesIfNeeded(
                sourceFilePaths,
                in: target.name,
                context: "Source File"
            )
            let resourceFilePaths = try collectResourceFiles(
                target: target,
                root: root
            )
            try validateDuplicatesIfNeeded(
                resourceFilePaths,
                in: target.name,
                context: "Resource"
            )
            let dependencies = target.dependencies
                .compactMap { $0.target?.name }
            try validateDuplicatesIfNeeded(
                dependencies,
                in: target.name,
                context: "Target Dependencies"
            )
            let frameworks = try extractFrameworks(target)
            try validateDuplicatesIfNeeded(
                frameworks,
                in: target.name,
                context: "Framework"
            )
            index[target.name] = TargetModel(
                name: target.name,
                buildableFilePaths: [],
                sourceFilePaths: Set(sourceFilePaths),
                resourceFilePaths: Set(resourceFilePaths),
                dependencies: Set(dependencies),
                frameworks: Set(frameworks)
            )
        }
        return index
    }

    func parseSynchronizedRootGroups(
        proj: XcodeProj,
        root: String,
        targetsIndex: inout [String: TargetModel]
    ) throws {
        for group in proj.pbxproj.fileSystemSynchronizedRootGroups {
            try processGroup(
                group: group,
                proj: proj.pbxproj,
                root: root,
                targetsIndex: &targetsIndex
            )
        }
    }

    func processGroup(
        group: PBXFileSystemSynchronizedRootGroup,
        proj: PBXProj,
        root: String,
        targetsIndex: inout [String: TargetModel]
    ) throws {
        guard let groupPath = try group.fullPath(sourceRoot: root) else {
            throw Error.failedToResolveBuildableFolderPath(group.path ?? "nil")
        }
        let linkedTargets =  linkedTargetsProviderFactory(group, proj)
        let groupFiles = try fileSystem.allFilePaths(in: groupPath)
        var groupFilesIndex = linkedTargets.reduce([String: Set<String>]()) { result, targetName in
            var mutableResult = result
            mutableResult[targetName] = groupFiles
            return mutableResult
        }
        if let exceptions = group.exceptions, !exceptions.isEmpty {
            // handle exceptions
            vPrint("Group path with exceptions: \(groupPath), linked targets: \(linkedTargets)")
            try applyExceptions(
                exceptions,
                groupPath: groupPath,
                proj: proj,
                groupFilesIndex: &groupFilesIndex
            )
        } else {
            vPrint("Group path: \(groupPath), linked targets: \(linkedTargets)")
            vPrint("  - Buildable folder files count: \(groupFiles.count)")
        }
        updateTargetsIndex(
            &targetsIndex,
            with: groupFilesIndex
        )
    }

    func applyExceptions(
        _ exceptions: [PBXFileSystemSynchronizedExceptionSet],
        groupPath: String,
        proj: PBXProj,
        groupFilesIndex: inout [String: Set<String>]
    ) throws {
        for exception in exceptions {
            if let exceptionSet = exception as? PBXFileSystemSynchronizedBuildFileExceptionSet {
                try applyMembershipExceptions(
                    exceptionSet,
                    groupPath: groupPath,
                    index: &groupFilesIndex
                )
            } else if let exceptionSet = exception as? PBXFileSystemSynchronizedGroupBuildPhaseMembershipExceptionSet {
                vPrint("  - Exception: \(exceptionSet), no need to handle for now")
            } else {
                assertionFailure(
                    "Unexpected exception type for group at path: \(groupPath) exception type: \(type(of: exception))"
                )
                continue
            }
        }
    }

    func applyMembershipExceptions(
        _ exceptionSet: PBXFileSystemSynchronizedBuildFileExceptionSet,
        groupPath: String,
        index: inout [String: Set<String>]
    ) throws {
        guard let target = exceptionSet.target else {
            throw Error.exceptionSetTargetIsNil(groupPath)
        }
        guard let productType = target.productType else {
            throw Error.exceptionSetTargetProductTypeIsNil(groupPath)
        }
        vPrint(
            "  - Exceptions: \(exceptionSet.membershipExceptions ?? []) " +
            "target: \(target.name), targetType: \(productType.rawValue)"
        )
        let exceptions = exceptionSet.membershipExceptions ?? []
        for membership in exceptions {
            switch productType {
            case .unitTestBundle, .uiTestBundle:
                let path = (groupPath as NSString).appendingPathComponent(membership)
                let current = index[target.name] ?? []
                index[target.name] = current.union([path])
            default:
                if let current = index[target.name] {
                    index[target.name] = current.filter { !$0.contains(membership)  }
                } else {
                    assertionFailure("No files found for target \(target.name) to apply exception \(membership)")
                }
            }
        }
    }

    func updateTargetsIndex(
        _ targetsIndex: inout [String: TargetModel],
        with groupFilesIndex: [String: Set<String>]
    ) {
        for (targetName, files) in groupFilesIndex {
            targetsIndex.insert(
                buildableFilePaths: files,
                forTargets: [targetName]
            )
        }
    }

    func extractReferencedSourceFiles(
        target: PBXNativeTarget,
        root: String
    ) throws -> [String] {
        try target.sourcesBuildPhase()?.files?
            .map {
                try $0.file?.fullPath(sourceRoot: root) ?? ""
            } ?? []
    }

    func extractFrameworks(_ target: PBXNativeTarget) throws -> [String] {
        try target.frameworksBuildPhase()?.files?
            .map {
                $0.product?.productName ?? $0.file?.path ?? ""
            } ?? []
    }

    func validateDuplicatesIfNeeded(
        _ items: [String],
        in targetName: String,
        context: String
    ) throws {
        guard
            let duplicatesValidationExcludedTargets = configuration.duplicatesValidationExcludedTargets
        else {
            try items.duplicatesValidation(context: context)
            return
        }
        guard duplicatesValidationExcludedTargets.contains(targetName) == false else {
            return
        }
        try items.duplicatesValidation(context: context)
    }

    func collectResourceFiles(
        target: PBXNativeTarget,
        root: String
    ) throws -> [String] {
        try target.resourcesBuildPhase()?.files?.map { file in
            let fullPath = try file.file?.fullPath(sourceRoot: root) ?? ""
            if let fileName = file.file?.name, fileName.contains(".strings") {
                return fullPath + "/" + fileName
            }
            return fullPath
        } ?? []
    }
}
