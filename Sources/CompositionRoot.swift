import Foundation
import XcodeProj

struct CompositionRoot {
    let configurationPath: String?
    let rootPath: String?
    let fileSystem: FileSystemProvider
    let defaultPath: String = ".xcode-targets.json"
    let vPrint: (String) -> Void
    let print: (String) -> Void
    private let linkedTargetsProviderFactory: (PBXFileSystemSynchronizedRootGroup, PBXProj) -> Set<String>

    var root: String {
        let rootPath = rootPath ?? fileSystem.currentDirectoryPath
        if rootPath.hasSuffix("/") {
            return rootPath
        } else {
            return rootPath + "/"
        }
    }

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
        let exclusivesProcessor = ExclusivesProcessor(vPrint: vPrint)
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
