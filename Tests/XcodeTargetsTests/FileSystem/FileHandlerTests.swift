import Foundation
import Testing
@testable import XcodeTargets

// MARK: - FileHandler Tests
@Suite("FileHandler Tests")
struct FileHandlerTests {
    // MARK: - Helpers
    private func makeTemporaryDirectory() throws -> URL {
        let tempRoot = URL(
            fileURLWithPath: NSTemporaryDirectory()
        ).appendingPathComponent(
            "FileHandlerTests_" + UUID().uuidString,
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
    private func canonicalized(_ urls: Set<URL>) -> Set<URL> {
        Set(urls.map { canonical($0) })
    }

    // MARK: - Duplicates Enumerator Stub
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
    @Test("test filterFiles given only files returns all file URLs")
    func test_filterFiles_givenOnlyFiles_returnsAllFileURLs() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let fileA = try writeFile(named: "A.txt", in: directory)
        let fileB = try writeFile(named: "B.txt", in: directory)
        let enumeratorOptional = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil
        )
        let enumerator = try #require(enumeratorOptional, "Expected directory enumerator")

        // When
        let result = FileHandler.filterFiles(from: enumerator)

        // Then
        let expected = canonicalized(Set([fileA, fileB]))
        #expect(canonicalized(result) == expected)
    }

    @Test("test filterFiles given files and directories returns only file URLs")
    func test_filterFiles_givenFilesAndDirectories_returnsOnlyFileURLs() throws {
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
        let enumeratorOptional = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil
        )
        let enumerator = try #require(
            enumeratorOptional,
            "Expected directory enumerator"
        )

        // When
        let result = FileHandler.filterFiles(from: enumerator)

        // Then
        let expected = canonicalized(Set([fileA, fileB]))
        let canonicalResult = canonicalized(result)
        #expect(canonicalResult == expected)
        #expect(canonicalResult.contains(canonical(subdirectory)) == false, "Directory should be excluded")
    }

    @Test("test filterFiles given empty directory returns empty set")
    func test_filterFiles_givenEmptyDirectory_returnsEmptySet() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let enumeratorOptional = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil
        )
        let enumerator = try #require(
            enumeratorOptional,
            "Expected directory enumerator"
        )

        // When
        let result = FileHandler.filterFiles(from: enumerator)

        // Then
        #expect(canonicalized(result).isEmpty)
    }

    @Test("test filterFiles given duplicate file URLs returns unique set")
    func test_filterFiles_givenDuplicateFileURLs_returnsUniqueSet() throws {
        // Given
        let directory = try makeTemporaryDirectory()
        let fileA = try writeFile(named: "A.txt", contents: "A", in: directory)
        let fileADuplicate = fileA // Intentional same URL to simulate duplicate enumeration
        let subdirectory = directory.appendingPathComponent(
            "Sub",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: subdirectory,
            withIntermediateDirectories: true
        )
        let stub = StubDirectoryEnumerator(urls: [fileA, fileADuplicate, subdirectory])

        // When
        let result = FileHandler.filterFiles(from: stub)

        // Then
        let canonicalResult = canonicalized(result)
        #expect(canonicalResult == canonicalized(Set([fileA])))
        #expect(canonicalResult.count == 1, "Result should collapse duplicates via Set semantics")
    }
}
