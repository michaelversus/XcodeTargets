@testable import XcodeTargets
import Testing

@Suite("DuplicatesError Tests")
struct DuplicatesErrorTests {

    @Test("test description for duplicateEntries error")
    func test_description() {
        // Given
        let duplicates = ["Item1", "Item2", "Item3"]
        let context = "testContext"
        let error = DuplicatesError.duplicateEntries(
            duplicates: duplicates,
            context: context
        )

        // When
        let description = error.description

        // Then
        let expectedDescription = "error: ❌ Duplicate testContext entries found:\nItem1, Item2, Item3"
        #expect(description == expectedDescription)
    }

}
