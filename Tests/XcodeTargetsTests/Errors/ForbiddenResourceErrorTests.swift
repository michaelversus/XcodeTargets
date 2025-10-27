import Testing
@testable import XcodeTargets

@Suite("ForbiddenResourceError Tests")
struct ForbiddenResourceErrorTests {

    @Test("test ForbiddenResourceError description")
    func testForbiddenResourceErrorDescription() {
        
        // Given
        let error = ForbiddenResourceError(
            targetName: "TargetA",
            matchingPaths: ["Sources/Forbidden/File.swift", "Sources/Forbidden/AnotherFile.swift"]
        )

        // When
        let description = error.description

        // Then
        #expect(description == "❌ Forbidden resource(s) found in target TargetA:\n - Sources/Forbidden/AnotherFile.swift\n - Sources/Forbidden/File.swift")
    }
}
