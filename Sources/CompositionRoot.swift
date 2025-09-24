import Foundation

struct CompositionRoot {
    let configurationPath: String?
    let rootPath: String?
    let fileManager: FileManagerProtocol
    let verbose: Bool
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
        verbose: Bool = false,
        vPrint: @escaping (String) -> Void = { print($0) }
    ) {
        self.configurationPath = configurationPath
        self.rootPath = rootPath ?? fileManager.currentDirectoryPath
        self.fileManager = fileManager
        self.verbose = verbose
        self.vPrint = vPrint
    }

    func run() throws {
        let configurationLoader = ConfigurationLoader(
            fileManager: fileManager,
            verbose: verbose,
            defaultPath: defaultPath,
            vPrint: vPrint
        )
        let configuration = try configurationLoader.loadConfiguration(
            at: configurationPath,
            root: root
        )
        let projectPath = root + configuration.name + ".xcodeproj"
        for fileMembershipSet in configuration.fileMembershipSets {
            let parser = XcodeProjectParser()
            for target in fileMembershipSet.targets {
                let parsedTarget = try parser.parseXcodeProjectTarget(
                    at: projectPath,
                    targetName: target,
                    root: root,
                    verbose: verbose
                )
                print("Target: \(parsedTarget.name)")
                print("Files count: \(parsedTarget.filePaths.count)")
                print("Files:")
                for file in parsedTarget.filePaths.sorted() {
                    print(" - \(file)")
                }
                print("\n")
            }
        }
    }
}
