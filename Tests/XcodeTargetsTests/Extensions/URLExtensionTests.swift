import Testing
import Foundation
@testable import XcodeTargets

@Suite("URL Extension Tests")
struct URLExtensionTests {

    @Test("test isDirectory returns true for directory URL")
    func testIsDirectoryReturnsTrueForDirectoryURL() throws {
        // Given
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        // When
        let isDirectory = try directoryURL.isDirectory()

        // Then
        #expect(isDirectory == true)
    }

    @Test("test isDirectory returns false for file URL")
    func testIsDirectoryReturnsFalseForFileURL() throws {
        // Given
        let fileURL = URL.Mock.exampleConfig

        // When
        let isDirectory = try fileURL.isDirectory()

        // Then
        #expect(isDirectory == false)
    }
}
