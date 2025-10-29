import ArgumentParser
import Foundation
import XcodeProj

/// Entry point for the `xcode-targets` command line tool.
///
/// The command loads and validates an `.xcode-targets.json` configuration file and
/// processes Xcode project targets to detect duplicates, exclusives, and forbidden resources.
///
/// Usage example:
///     xcode-targets --config path/to/.xcode-targets.json --rootPath /path/to/project --verbose
///
/// Provide `--verbose` (or `-v`) to enable additional diagnostic output.
@main
struct XcodeTargets: ParsableCommand {
    /// The path to the `.xcode-targets.json` configuration file.
    /// If omitted, the tool attempts to locate a configuration in the current directory.
    @Option(name: [.short, .customLong("config")], help: "The path of `.xcode-targets.json`.")
    var configurationPath: String?

    /// The root path of the project to analyze.
    /// Defaults to the current working directory when not provided.
    @Option(
        name: .shortAndLong,
        help: "The rootPath of your project. Defaults to current directory."
    )
    var rootPath: String?

    /// Flag to enable verbose output for diagnostic purposes.
    @Option(name: .shortAndLong, help: "Flag to enable verbose output.")
    var verbose: Bool = false

    /// Executes the command: loads configuration, initializes dependencies, and runs processing.
    ///
    /// - Throws: Rethrows any errors encountered during configuration loading, file system access,
    ///           or Xcode project parsing and validation.
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
            vPrint: { if verbose { print($0) } },
            linkedTargetsProviderFactory: { group, proj in
                LinkedTargetsProvider(proj: proj).linkedTargets(group: group)
            }
        )
        try compositionRoot.run()
    }
}
