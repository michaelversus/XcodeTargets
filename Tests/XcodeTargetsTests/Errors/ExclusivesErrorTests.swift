@testable import XcodeTargets
import Testing

@Suite("ExclusivesError Tests")
struct ExclusivesErrorTests {

    @Test("test description of invalidTargetName")
    func test_descriptionGivenInvalidTargetName() throws {
        // Given
        let sut = ExclusivesError.invalidTargetName("MyTarget")

        // When
        let description = sut.description

        // Then
        #expect(description == "❌ Target name MyTarget inside exclusive section doesn't exist in the project")
    }

    @Test("test description of invalidPathForTarget")
    func test_descriptionGivenInvalidPathForTarget() throws {
        // Given
        let sut = ExclusivesError.invalidPathForTarget(targetName: "MyTarget", path: "Sources/NonExistent")

        // When
        let description = sut.description

        // Then
        #expect(description == "❌ Path Sources/NonExistent inside exclusive section for target MyTarget doesn't exist in the project")
    }

    @Test("test description of exclusiveEntriesFound")
    func test_descriptionGivenExclusiveEntriesFound() throws {
        // Given
        let sut = ExclusivesError.exclusiveEntriesFound(targetNames: "MyTarget1, MyTarget2")

        // When
        let description = sut.description

        // Then
        #expect(description == "❌ Exclusive entries found for targets: MyTarget1, MyTarget2")
    }
}
