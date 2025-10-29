import Foundation
import XcodeProj

/// The CompositionRoot coordinates the high-level workflow for validating Xcode targets
/// against a JSON configuration. It loads the configuration, parses the Xcode project,
/// and executes validation passes (exclusives and forbidden resources).
///
/// Responsibilities:
/// - Resolve root and configuration paths
/// - Load configuration JSON via `ConfigurationLoader`
/// - Parse the Xcode project structure via `XcodeProjectParser`
/// - Execute validation processors (`ExclusivesProcessor`, `ForbiddenResourcesProcessor`)
/// - Report success or surface thrown errors to the caller
struct CompositionRoot {
    /// Optional override path for the configuration file provided by the caller.
    let configurationPath: String?
    /// Optional override path for the project root directory. Falls back to current working directory when nil.
    let rootPath: String?
    /// Abstraction over file system interactions.
    let fileSystem: FileSystemProvider
    /// Default relative path used when no explicit configuration path is supplied.
    let defaultPath: String = ".xcode-targets.json"
    /// Verbose print closure for diagnostic output.
    let vPrint: (String) -> Void
    /// Standard print closure for user-facing messages.
    let print: (String) -> Void
    /// Factory that creates a provider of linked targets from a synchronized root group and project.
    private let linkedTargetsProviderFactory: (PBXFileSystemSynchronizedRootGroup, PBXProj) -> Set<String>

    /// Resolved root path guaranteed to end with a trailing slash for consistent path concatenation.
    var root: String {
        let rootPath = rootPath ?? fileSystem.currentDirectoryPath
        if rootPath.hasSuffix("/") {
            return rootPath
        } else {
            return rootPath + "/"
        }
    }

    /// Initializes a new composition root.
    /// - Parameters:
    ///   - configurationPath: Optional explicit configuration file path.
    ///   - rootPath: Optional explicit root directory path.
    ///   - fileSystem: Dependency used for file system operations.
    ///   - print: Closure for standard output messages.
    ///   - vPrint: Closure for verbose diagnostic messages.
    ///   - linkedTargetsProviderFactory: Factory closure producing a set of linked target names.
    init(
        configurationPath: String?,
        rootPath: String?,
        fileSystem: FileSystemProvider,
        print: @escaping (String) -> Void,
        vPrint: @escaping (String) -> Void,
        linkedTargetsProviderFactory: @escaping (PBXFileSystemSynchronizedRootGroup, PBXProj) -> Set<String>
    ) {
        self.configurationPath = configurationPath
        self.rootPath = rootPath ?? fileSystem.currentDirectoryPath
        self.fileSystem = fileSystem
        self.print = print
        self.vPrint = vPrint
        self.linkedTargetsProviderFactory = linkedTargetsProviderFactory
    }

    /// Executes the end-to-end validation workflow.
    ///
    /// Workflow steps:
    /// 1. Load configuration JSON.
    /// 2. Parse the Xcode project and build an in-memory targets index.
    /// 3. Process exclusives (validates exclusive file membership, creates derived targets as needed).
    /// 4. Check for forbidden resources in targets.
    /// 5. Print a success confirmation if all validations pass.
    ///
    /// - Throws: Rethrows any error encountered during configuration loading, project parsing,
    ///           exclusives processing, or forbidden resources validation.
    func run() throws {
        let configurationLoader = ConfigurationLoader(
            fileSystem: fileSystem,
            defaultPath: defaultPath,
            print: print
        )
        let configuration = try configurationLoader.loadConfiguration(
            at: configurationPath,
            root: root
        )
        let projectPath = root + configuration.name + ".xcodeproj"
        let parser = XcodeProjectParser(
            fileSystem: fileSystem,
            configuration: configuration,
            print: print,
            vPrint: vPrint,
            linkedTargetsProviderFactory: linkedTargetsProviderFactory
        )
        let targetsIndex = try parser.parseXcodeProject(at: projectPath, root: root)

        // Step 1
        // Parse exclusive files or wildcard directories path/* or path/.*
        // Check if they are included inside the proper target.
        // Check that they are not included in other targets.
        // Create new targets that don't have excluded files
        // Check if rest of files are common for all fileMembershipSets
        let exclusivesProcessor = ExclusivesProcessor(print: print)
        try exclusivesProcessor.process(
            configuration: configuration,
            originalTargetsIndex: targetsIndex
        )

        // Step 2
        // use forbiddenResourceSets to validate if we have any forbidden resources in targets
        let forbiddenResourcesProcessor = ForbiddenResourcesProcessor(vPrint: vPrint)
        try forbiddenResourcesProcessor.process(
            configuration: configuration,
            targetsIndex: targetsIndex
        )
        // Final message
        print("✅ Xcode Targets validation completed successfully.")
    }
}
