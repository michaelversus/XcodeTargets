@testable import XcodeTargets
import Testing

struct ArrayExtensionTests {
    private let context = "testContext"

    @Test("test duplicatesValidation given no duplicates does not throw")
    func test_duplicatesValidation_givenNoDuplicates_doesNotThrow() throws {
        // Given
        let array = ["A", "B", "C"]

        // When, Then
        try array.duplicatesValidation(context: context)
    }

    @Test("test duplicatesValidation given duplicates throws DuplicatesError")
    func test_duplicatesValidation_givenDuplicates_throwsDuplicatesError() throws {
        // Given
        let array = ["A", "B", "A", "C", "B"]

        // When, Then
        #expect(throws: DuplicatesError.self, performing: {
            try array.duplicatesValidation(context: context)
        })
    }
}
