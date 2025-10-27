import Foundation
import Testing
@testable import XcodeTargets

@Suite("ConfigLoader Tests")
struct ConfigLoaderTests {
    var fileSystem = FileSystemMock()

    @Test("test Load config from file")
    func testLoadConfigFromFile() throws {
        // Given
        fileSystem.fileExistsReturnValue = true
        let rootPath = URL.Mock.exampleConfig.deletingLastPathComponent().path + "/"
        let configPath = "xcode-targets.json"
        let sut = makeSut()

        // When
        let configuration = try sut.loadConfiguration(at: configPath, root: rootPath)

        // Then
        #expect(configuration == Configuration.mock)
    }

    @Test("test Load config from default path")
    func testLoadConfigFromDefaultPath() throws {
        // Given
        fileSystem.fileExistsReturnValue = true
        let rootPath = URL.Mock.exampleConfig.deletingLastPathComponent().path + "/"
        let sut = makeSut(defaultPath: "xcode-targets.json")

        // When
        let configuration = try sut.loadConfiguration(at: nil, root: rootPath)

        // Then
        #expect(configuration == Configuration.mock)
    }

    @Test("test Load config file not found throws error")
    func testLoadConfigFileNotFoundThrowsError() throws {
        // Given
        fileSystem.fileExistsReturnValue = false
        let rootPath = URL.Mock.exampleConfig.deletingLastPathComponent().path + "/"
        let sut = makeSut()

        // When, Then
        #expect(
            throws: ConfigurationLoaderError.configurationFileNotFound("\(rootPath).xcode-targets.json"),
            performing: {
                _ = try sut.loadConfiguration(at: nil, root: rootPath)
            }
        )
    }

    @Test("test Load config verbose prints message")
    func testLoadConfigVerbosePrintsMessage() throws {
        // Given
        fileSystem.fileExistsReturnValue = true
        let rootPath = URL.Mock.exampleConfig.deletingLastPathComponent().path + "/"
        let configPath = "xcode-targets.json"
        var verboseMessages: [String] = []
        let sut = makeSut() { message in
            verboseMessages.append(message)
        }

        // When
        _ = try sut.loadConfiguration(at: configPath, root: rootPath)

        // Then
        #expect(verboseMessages == ["Loading configuration from: \(rootPath)\(configPath)"])
    }


}

extension ConfigLoaderTests {
    func makeSut(
        defaultPath: String = ".xcode-targets.json",
        print: @escaping (String) -> Void = { _ in }
    ) -> ConfigurationLoader {
        ConfigurationLoader(
            fileSystem: fileSystem,
            defaultPath: defaultPath,
            print: print
        )
    }
}
