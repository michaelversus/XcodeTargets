import Foundation

struct CompositionRoot {
    let configurationPath: String?
    let rootPath: String?
    let fileManager: FileManagerProtocol
    let defaultPath: String = ".xcode-targets.json"
    let vPrint: (String) -> Void

    var root: String {
        let rootPath = rootPath ?? fileManager.currentDirectoryPath
        if rootPath.hasSuffix("/") {
            return rootPath
        } else {
            return rootPath + "/"
        }
    }

    init(
        configurationPath: String? = nil,
        rootPath: String? = nil,
        fileManager: FileManagerProtocol,
        vPrint: @escaping (String) -> Void = { print($0) }
    ) {
        self.configurationPath = configurationPath
        self.rootPath = rootPath ?? fileManager.currentDirectoryPath
        self.fileManager = fileManager
        self.vPrint = vPrint
    }

    func run() throws {
        let configurationLoader = ConfigurationLoader(
            fileManager: fileManager,
            defaultPath: defaultPath,
            vPrint: vPrint
        )
        let configuration = try configurationLoader.loadConfiguration(
            at: configurationPath,
            root: root
        )
        let projectPath = root + configuration.name + ".xcodeproj"
        let parser = XcodeProjectParser(
            fileManager: fileManager,
            configuration: configuration,
            vPrint: vPrint
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
    }
}
