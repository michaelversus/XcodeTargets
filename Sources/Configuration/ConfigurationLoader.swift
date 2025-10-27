import Foundation

struct ConfigurationLoader {
    let fileSystem: FileSystemProvider
    let defaultPath: String
    let print: (String) -> Void

    init(
        fileSystem: FileSystemProvider,
        defaultPath: String = ".xcode-targets.json",
        print: @escaping (String) -> Void
    ) {
        self.fileSystem = fileSystem
        self.defaultPath = defaultPath
        self.print = print
    }

    func loadConfiguration(at path: String?, root: String) throws -> Configuration {
        let configurationPath: String
        if let path {
            configurationPath = path.hasPrefix("/") ? path : root + path
        } else {
            configurationPath = root + defaultPath
        }
        guard fileSystem.fileExists(atPath: configurationPath) else {
            throw ConfigurationLoaderError.configurationFileNotFound(configurationPath)
        }
        print("Loading configuration from: \(configurationPath)")
        let data = try Data(contentsOf: URL(fileURLWithPath: configurationPath))
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(Configuration.self, from: data)
        return configuration
    }
}
