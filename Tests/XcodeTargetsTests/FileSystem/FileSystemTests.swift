import Foundation
import Testing
@testable import XcodeTargets

// MARK: - FileSystem Tests
@Suite("FileSystem Tests")
struct FileSystemTests {
    // MARK: - Helpers
    private func makeTemporaryDirectory() throws -> URL {
        let tempRoot = URL(
            fileURLWithPath: NSTemporaryDirectory()
        ).appendingPathComponent(
            "FileSystemTests_" + UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: tempRoot,
            withIntermediateDirectories: true
        )
        return tempRoot
    }

    private func writeFile(
        named name: String,
        contents: String = "test",
        in directory: URL
    ) throws -> URL {
        let fileURL = directory.appendingPathComponent(name)
        try contents.data(using: .utf8)?
            .write(to: fileURL)
        return fileURL
    }

    private func canonical(_ url: URL) -> URL { url.resolvingSymlinksInPath() }
    private func canonicalized(_ urls: Set<URL>) -> Set<URL> { Set(urls.map { canonical($0) }) }

    // MARK: - Stub Directory Enumerator
    private final class StubDirectoryEnumerator: FileManager.DirectoryEnumerator {
        private let objects: [Any]
        private var index = 0

        init(urls: [URL]) {
            self.objects = urls
            super.init()
        }

        override func nextObject() -> Any? {
            guard index < objects.count else { return nil }
            defer { index += 1 }
            return objects[index]
        }
    }

    // MARK: - Tests
    @Test("test allFiles given enumeratorFactory returns nil returns empty set")
    func test_allFiles_givenEnumeratorFactoryReturnsNil_returnsEmptySet() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let system = FileSystem(enumeratorFactory: { _ in nil })

        // When
        let result = try system.allFiles(in: directory)

        // Then
        #expect(result.isEmpty)
    }

    @Test("test allFiles given files and directories returns only files")
    func test_allFiles_givenFilesAndDirectories_returnsOnlyFiles() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let subdirectory = directory.appendingPathComponent(
            "Sub",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: subdirectory,
            withIntermediateDirectories: true
        )
        let fileA = try writeFile(named: "A.txt", in: directory)
        let fileB = try writeFile(named: "B.txt", in: subdirectory)
        let stub = StubDirectoryEnumerator(urls: [fileA, subdirectory, fileB])
        let system = FileSystem(enumeratorFactory: { _ in stub })

        // When
        let result = try system.allFiles(in: directory)

        // Then
        let expected = canonicalized(Set([fileA, fileB]))
        let canonicalResult = canonicalized(result)
        #expect(canonicalResult == expected)
        #expect(canonicalResult.contains(canonical(subdirectory)) == false, "Directory should be excluded")
    }

    @Test("test allFiles given duplicate file URLs collapses duplicates")
    func test_allFiles_givenDuplicateFileURLs_collapsesDuplicates() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let fileA = try writeFile(named: "A.txt", contents: "A", in: directory)
        let duplicate = fileA
        let stub = StubDirectoryEnumerator(urls: [fileA, duplicate])
        let system = FileSystem(enumeratorFactory: { _ in stub })

        // When
        let result = try system.allFiles(in: directory)

        // Then
        let canonicalResult = canonicalized(result)
        #expect(canonicalResult == canonicalized(Set([fileA])))
        #expect(canonicalResult.count == 1)
    }

    @Test("test allFilePaths given files returns absoluteString set of files")
    func test_allFilePaths_givenFiles_returnsAbsoluteStringSetOfFiles() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let fileA = try writeFile(named: "A.txt", in: directory)
        let fileB = try writeFile(named: "B.txt", in: directory)
        let stub = StubDirectoryEnumerator(urls: [fileA, fileB])
        let system = FileSystem(enumeratorFactory: { _ in stub })

        // When
        let result = try system.allFilePaths(in: directory.path)

        // Then
        let expected = Set([fileA.absoluteString, fileB.absoluteString])
        #expect(result == expected)
    }

    @Test("test fileExists given existing and non-existing paths returns correct booleans")
    func test_fileExists_givenExistingAndNonExistingPaths_returnsCorrectBooleans() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let fileA = try writeFile(named: "A.txt", in: directory)
        let nonExisting = directory.appendingPathComponent("Nope.txt").path
        let system = FileSystem(enumeratorFactory: { _ in nil })

        // When / Then
        #expect(system.fileExists(atPath: fileA.path) == true)
        #expect(system.fileExists(atPath: nonExisting) == false)
    }

    @Test("test currentDirectoryPath reflects injected fileManager current directory")
    func test_currentDirectoryPath_reflectsInjectedFileManagerCurrentDirectory() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let fileManager = FileManager()
        let changed = fileManager.changeCurrentDirectoryPath(directory.path)
        #expect(changed == true, "Expected to change current directory path")
        let system = FileSystem(fileManager: fileManager, enumeratorFactory: { _ in nil })

        // When
        let path = system.currentDirectoryPath

        // Then
        // Resolve potential /private/ var symlink discrepancy
        let expectedCanonical = canonical(directory).path
        let actualCanonical = canonical(URL(fileURLWithPath: path)).path
        #expect(actualCanonical == expectedCanonical, "Canonical current directory path should match")
    }

    @Test("test currentDirectoryPath canonicalization handles /private prefix")
    func test_currentDirectoryPath_canonicalization_handlesPrivatePrefix() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let fileManager = FileManager()
        _ = fileManager.changeCurrentDirectoryPath(directory.path)
        let system = FileSystem(
            fileManager: fileManager,
            enumeratorFactory: { _ in nil
            }
        )

        // When
        let rawPath = system.currentDirectoryPath

        // Then
        let rawURL = URL(fileURLWithPath: rawPath)
        let canonicalRaw = canonical(rawURL).path
        let canonicalDir = canonical(directory).path
        #expect(canonicalRaw == canonicalDir)
    }
}
