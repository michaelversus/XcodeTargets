import ArgumentParser
import Foundation

@main
struct XcodeTargets: ParsableCommand {
    // @Option(name: [.short, .customLong("config")], help: "The path of `.xcode-targets.json`.")
    var configurationPath: String? = ".xcode-targets.json"

//    @Option(
//        name: .shortAndLong,
//        help: "The rootPath of your project. Defaults to current directory."
//    )
    var rootPath: String? = "/Users/m.karagiorgos/iosnative/"

    // @Option(name: .shortAndLong, help: "Flag to enable verbose output.")
    var verbose: Bool = false

    func run() throws {
        let fileSystem = FileSystem(
            fileManager: FileManager.default,
            enumeratorFactory: { url in
                FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: nil
                )
            }
        )
        let compositionRoot = CompositionRoot(
            configurationPath: configurationPath,
            rootPath: rootPath,
            fileSystem: fileSystem,
            print: { print($0) },
            vPrint: { if verbose { print($0) } }
        )
        try compositionRoot.run()
    }
}
