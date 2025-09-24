import Foundation

struct ConfigurationLoader {
    let fileManager: FileManagerProtocol
    let verbose: Bool
    let defaultPath: String
    let vPrint: (String) -> Void

    init(
        fileManager: FileManagerProtocol,
        verbose: Bool = false,
        defaultPath: String = ".xcode-targets.json",
        vPrint: @escaping (String) -> Void = { print($0) }
    ) {
        self.fileManager = fileManager
        self.verbose = verbose
        self.defaultPath = defaultPath
        self.vPrint = vPrint
    }

    func loadConfiguration(at path: String?, root: String) throws -> Configuration {
        let configurationPath: String
        if let path {
            configurationPath = path.hasPrefix("/") ? path : root + path
        } else {
            configurationPath = root + defaultPath
        }

        guard fileManager.fileExists(atPath: configurationPath) else {
            throw ConfigurationLoaderError.configurationFileNotFound(configurationPath)
        }

        if verbose {
            vPrint("Loading configuration from: \(configurationPath)")
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: configurationPath))
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(Configuration.self, from: data)
        return configuration
    }
}
