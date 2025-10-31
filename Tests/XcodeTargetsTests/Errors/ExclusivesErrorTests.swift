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
        let sut = ExclusivesError.exclusiveEntriesFound(
            targetNames: "MyTarget1, MyTarget2",
            diff: Target(
                name: "Difference",
                filePaths: [
                    "/path/to/file.swift",
                    "/another/path/to/file.swift"
                ],
                dependencies: [
                    "SomeTargetA",
                    "SomeTargetB"
                ],
                frameworks: [
                    "SomeFrameworkA",
                    "SomeFrameworkB"
                ]
            )
        )

        // When
        let description = sut.description

        // Then
        var expectedDescription = "❌ Exclusive entries found for targets: MyTarget1, MyTarget2\n"
        expectedDescription += " Conflicting files:\n"
        expectedDescription += " - /another/path/to/file.swift\n"
        expectedDescription += " - /path/to/file.swift\n"
        expectedDescription += " Conflicting dependencies:\n"
        expectedDescription += " - SomeTargetA\n"
        expectedDescription += " - SomeTargetB\n"
        expectedDescription += " Conflicting frameworks:\n"
        expectedDescription += " - SomeFrameworkA\n"
        expectedDescription += " - SomeFrameworkB\n"
        #expect(description == expectedDescription)
    }
}
