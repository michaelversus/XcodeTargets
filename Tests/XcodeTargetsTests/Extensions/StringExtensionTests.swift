import Testing
@testable import XcodeTargets

@Suite("String Extension Tests")
struct StringExtensionTests {

    @Test("test dropWildCards removes /* suffix")
    func testDropWildCardsRemovesAsteriskSlashSuffix() {
        // Given
        let input = "Sources/Folder/*"
        let expectedOutput = "Sources/Folder/"

        // When
        let output = input.dropWildCards()

        // Then
        #expect(output == expectedOutput)
    }

    @Test("test dropWildCards removes /.* suffix")
    func testDropWildCardsRemovesDotAsteriskSuffix() {
        // Given
        let input = "Sources/Folder/.*"
        let expectedOutput = "Sources/Folder/"

        // When
        let output = input.dropWildCards()

        // Then
        #expect(output == expectedOutput)
    }

    @Test("test dropWildCards leaves string unchanged when no wildcard suffix")
    func testDropWildCardsLeavesStringUnchangedWhenNoWildcardSuffix() {
        // Given
        let input = "Sources/Folder/File.swift"
        let expectedOutput = "Sources/Folder/File.swift"

        // When
        let output = input.dropWildCards()

        // Then
        #expect(output == expectedOutput)
    }
}
