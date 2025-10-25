import ArgumentParser
import Foundation

@main
struct XcodeTargets: ParsableCommand {
    //@Option(name: [.short, .customLong("config")], help: "The path of `.xcode-targets.json`.")
    var configurationPath: String? = ".xcode-targets.json"

    //@Option(name: .shortAndLong, help: "The rootPath of your project. If you omit this, the current directory will be used.")
    var rootPath: String? = "/Users/m.karagiorgos/iosnative/"

    //@Option(name: .shortAndLong, help: "Flag to enable verbose output.")
    var verbose: Bool = false

    func run() throws {
        let compositionRoot = CompositionRoot(
            configurationPath: configurationPath,
            rootPath: rootPath,
            fileManager: FileManager.default,
            vPrint: {
                if verbose {
                    print($0)
                }
            }
        )
        try compositionRoot.run()
    }
}
