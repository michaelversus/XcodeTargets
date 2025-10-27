import Testing
import Foundation
@testable import XcodeTargets
import XcodeProj

@Suite("XcodeProjectParser Tests")
final class XcodeProjectParserTests {
    var fileSystem = FileSystemMock()
    var configuration: Configuration = .empty
    var messages: [String] = []
    lazy var print: (String) -> Void = { [weak self] message in
        self?.messages.append(message)
    }
    var linkedTargets: Set<String> = []

    @Test("test parse project at invalid path throws error")
    func test_parseProjectAtInvalidPath() throws {
        // Given
        let invalidPath = "/invalid/path/to/project.xcodeproj"
        let sut = makeSUT()

        // When
        let error = #expect(throws: XCodeProjError.self) {
            try sut.parseXcodeProject(at: invalidPath, root: "")
        }

        // Then
        switch error {
        case .notFound(let path):
            #expect(path.string == invalidPath)
        default:
            Issue.record("Expected .notFound error, but got \(String(describing: error))")
        }
    }

    @Test("test parse project at valid path given duplicate source files throws error")
    func test_parseProjectAtValidPathGivenDuplicateSourceFiles() throws {
        // Given
        let validPath = try duplicateSourceFilesProjectPath().relativePath
        let sut = makeSUT()

        // When
        let error = #expect(throws: DuplicatesError.self) {
            try sut.parseXcodeProject(at: validPath, root: "Fixtures")
        }

        // Then
        switch error {
        case .duplicateEntries(let duplicates, let context):
            let duplicate = try #require(duplicates.first)
            #expect(duplicate.hasSuffix("Fixtures/New Group/ContentView.swift"))
            #expect(context == "Source File")
        case .none:
            Issue.record("Expected .duplicateEntries error, but got none")
        }
        let expectedMessages = [
            "Parsing Xcode project at path: \(validPath)",
            "Parsing Target: DuplicateSourceFiles"
        ]
        #expect(messages == expectedMessages)
    }

    @Test("test parse project at valid path given duplicate source files and config.duplicatesValidationExcludedTargets skips error")
    func test_parseProjectAtValidPathGivenDuplicateSourceFilesAndExclusionSkipsError() throws {
        // Given
        let validPath = try duplicateSourceFilesProjectPath().relativePath
        configuration = Configuration(
            name: "Example",
            fileMembershipSets: [],
            forbiddenResourceSets: [],
            duplicatesValidationExcludedTargets: ["DuplicateSourceFiles"]
        )
        let sut = makeSUT()

        // When
        _ = try sut.parseXcodeProject(at: validPath, root: "Fixtures")

        // Then
        let expectedMessages = [
            "Parsing Xcode project at path: \(validPath)",
            "Parsing Target: DuplicateSourceFiles",
            "Target: DuplicateSourceFiles total files: 1",
            "  Buildable files: 0",
            "  Source files: 1",
            "  Resource files: 0",
            "  Dependencies: 0",
            "  Frameworks: 0"
        ]
        #expect(messages == expectedMessages)
    }

    // TODO:
    // 1. 2 tests for duplicate resources
    // 2. 2 tests for duplicate target dependencies
    // 3. 2 tests for duplicate frameworks
    // 4. tests for parseSynchronizedRootGroups
    // 5. separate the error enum to test the descriptions

}

private extension XcodeProjectParserTests {
    func makeSUT() -> XcodeProjectParser {
        XcodeProjectParser(
            fileSystem: fileSystem,
            configuration: configuration,
            print: { [weak self] in self?.print($0) },
            vPrint: { _ in  },
            linkedTargetsProviderFactory: { [weak self] _, _ in
                self?.linkedTargets ?? []
            }
        )
    }
}
