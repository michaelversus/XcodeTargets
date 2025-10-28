import PathKit
import XcodeProj
import Foundation

/// Parses an Xcode project to build an index of target models, extracting source files, resources,
/// frameworks, dependencies and buildable (synchronized) group file paths. Duplicate validation
/// rules and exception handling are applied based on the provided `Configuration`.
struct XcodeProjectParser {
    private let fileSystem: FileSystemProvider
    private let configuration: Configuration
    private let print: (String) -> Void
    private let vPrint: (String) -> Void
    private let linkedTargetsProviderFactory: (PBXFileSystemSynchronizedRootGroup, PBXProj) -> Set<String>

    /// Initializes a new parser.
    /// - Parameters:
    ///   - fileSystem: Abstraction for file system access (e.g. listing files in synchronized groups).
    ///   - configuration: Runtime configuration affecting duplicate validation exclusions.
    ///   - print: Closure used for user‑facing output (summary and high‑level progress).
    ///   - vPrint: Closure used for verbose / diagnostic output.
    ///   - linkedTargetsProviderFactory: Factory closure producing the set of target names linked to a synchronized root group.
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

    /// Parses the Xcode project at the given path building an index keyed by target name.
    /// The index aggregates source files, resource files, frameworks, dependencies and buildable files
    /// (collected from file system synchronized root groups plus their exceptions).
    /// - Parameters:
    ///   - path: File system path to the *.xcodeproj bundle.
    ///   - root: Absolute path to the project source root used by `XcodeProj` to resolve file references.
    /// - Returns: Dictionary keyed by target name containing its aggregated `TargetModel`.
    /// - Throws: `XcodeProjectParserError` when resolution of paths or exception targets fails, or
    ///           other errors surfaced while loading the project or validating duplicates.
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
    /// Loads and initializes the `XcodeProj` representation for the project at the provided path.
    /// - Parameter path: Path to the *.xcodeproj bundle.
    /// - Returns: Parsed `XcodeProj` instance.
    /// - Throws: Any error thrown by `XcodeProj` while reading the project structure.
    func makeProject(at path: String) throws -> XcodeProj {
        let projectPath = Path(path)
        return try XcodeProj(path: projectPath)
    }
    /// Builds the initial target index containing source files, resources, dependencies and frameworks.
    /// - Parameters:
    ///   - proj: Parsed project wrapper.
    ///   - root: Source root for resolving file references.
    /// - Returns: Dictionary keyed by target name with preliminary `TargetModel` values (without buildable files yet).
    /// - Throws: Errors while resolving file paths or duplicate validation failures.
    func parseTargets(
        proj: XcodeProj,
        root: String
    ) throws -> [String: TargetModel] {
        var index: [String: TargetModel] = [:]
        let sortedTargetNames = proj.pbxproj.nativeTargets.sorted(by: { $0.name < $1.name })
        for target in sortedTargetNames {
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

    /// Enriches the target index with buildable files by traversing synchronized root groups and applying exceptions.
    /// - Parameters:
    ///   - proj: Parsed project wrapper (pbxproj used for group traversal).
    ///   - root: Source root for path resolution.
    ///   - targetsIndex: In/out target index updated with buildable file paths.
    /// - Throws: Errors raised while resolving group paths or applying exception sets.
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

    /// Processes one synchronized root group, collecting its files and applying membership exceptions per target.
    /// - Parameters:
    ///   - group: The synchronized root group to process.
    ///   - proj: Underlying PBX project reference for target resolution.
    ///   - root: Source root.
    ///   - targetsIndex: Index updated with buildable files.
    /// - Throws: Parser errors when paths or exception targets/product types cannot be resolved.
    func processGroup(
        group: PBXFileSystemSynchronizedRootGroup,
        proj: PBXProj,
        root: String,
        targetsIndex: inout [String: TargetModel]
    ) throws {
        guard let groupPath = try group.fullPath(sourceRoot: root) else {
            throw XcodeProjectParserError.failedToResolveBuildableFolderPath(group.path ?? "nil")
        }
        let linkedTargets =  linkedTargetsProviderFactory(group, proj).sorted()
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

    /// Applies each exception set found in a synchronized group, delegating to membership exception handling.
    /// - Parameters:
    ///   - exceptions: Collection of raw exception sets.
    ///   - groupPath: Resolved path of the group being processed.
    ///   - proj: PBX project for target lookups.
    ///   - groupFilesIndex: In/out map of target name to its buildable files affected by exceptions.
    /// - Throws: Parser errors when required target/product type metadata is missing.
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

    /// Applies membership exceptions for a target within a synchronized group.
    /// Test bundles add specified files; other product types remove matching file memberships.
    /// - Parameters:
    ///   - exceptionSet: Build file exception set describing membership changes.
    ///   - groupPath: Base path of the synchronized group.
    ///   - index: In/out index mapping target names to buildable files sets.
    /// - Throws: Parser errors if target or product type metadata is missing.
    func applyMembershipExceptions(
        _ exceptionSet: PBXFileSystemSynchronizedBuildFileExceptionSet,
        groupPath: String,
        index: inout [String: Set<String>]
    ) throws {
        guard let target = exceptionSet.target else {
            throw XcodeProjectParserError.exceptionSetTargetIsNil(groupPath)
        }
        guard let productType = target.productType else {
            throw XcodeProjectParserError.exceptionSetTargetProductTypeIsNil(groupPath)
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
                    vPrint("No files found for target \(target.name) to apply exception \(membership)")
                }
            }
        }
    }

    /// Updates the master target index with buildable file paths for each target in the group index.
    /// - Parameters:
    ///   - targetsIndex: Master target index to update.
    ///   - groupFilesIndex: Mapping of target name to collected buildable files.
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

    /// Extracts full paths of referenced source files in a target's sources build phase.
    /// - Parameters:
    ///   - target: The native target whose source files are collected.
    ///   - root: Source root used for path resolution.
    /// - Returns: Array of resolved file paths (empty if none).
    /// - Throws: Errors thrown during path resolution by `fullPath`.
    func extractReferencedSourceFiles(
        target: PBXNativeTarget,
        root: String
    ) throws -> [String] {
        try target.sourcesBuildPhase()?.files?
            .map {
                try $0.file?.fullPath(sourceRoot: root) ?? ""
            } ?? []
    }

    /// Extracts the names/paths of frameworks referenced in the framework build phase.
    /// - Parameter target: Native target whose frameworks are collected.
    /// - Returns: Array of product names or raw file paths for each framework.
    /// - Throws: Errors during framework phase traversal.
    func extractFrameworks(_ target: PBXNativeTarget) throws -> [String] {
        try target.frameworksBuildPhase()?.files?
            .map {
                $0.product?.productName ?? $0.file?.path ?? ""
            } ?? []
    }

    /// Validates duplicate items unless the target is explicitly excluded in configuration.
    /// - Parameters:
    ///   - items: Items to check for duplicates.
    ///   - targetName: Name of the target owning the items.
    ///   - context: Human‑readable context (e.g. "Source File", "Resource").
    /// - Throws: `DuplicatesError` surfaced via `duplicatesValidation` when duplicates are found.
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

    /// Collects resource file paths from a target's resources build phase, adjusting paths for .strings bundles.
    /// - Parameters:
    ///   - target: Native target whose resources are collected.
    ///   - root: Source root for path resolution.
    /// - Returns: Array of resource file paths (empty if none).
    /// - Throws: Errors during path resolution for resource files.
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
