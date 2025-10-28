import Testing
@testable import XcodeTargets

@Suite("XcodeProjectParserError Tests")
struct XcodeProjectParserErrorTests {
    // MARK: - description
    @Test("test description with invalid target name returns expected message")
    func test_description_WithInvalidTargetName_returnsExpectedMessage() {
        // Given
        let name = "InvalidTarget"
        let sut = XcodeProjectParserError.invalidTargetName(name)

        // When
        let message = sut.description

        // Then
        #expect(message == "❌ Invalid target name InvalidTarget")
    }

    @Test("test description with invalid path returns expected message")
    func test_description_WithInvalidPath_returnsExpectedMessage() {
        // Given
        let path = "Some/Invalid/Path"
        let sut = XcodeProjectParserError.invalidPath(path)

        // When
        let message = sut.description

        // Then
        #expect(message == "❌ Invalid path Some/Invalid/Path")
    }

    @Test("test description with failed to resolve buildable folder path returns expected message")
    func test_description_WithFailedToResolveBuildableFolderPath_returnsExpectedMessage() {
        // Given
        let path = "Sources/Module/Buildable"
        let sut = XcodeProjectParserError.failedToResolveBuildableFolderPath(path)

        // When
        let message = sut.description

        // Then
        #expect(message == "❌ Failed to resolve buildable folder path Sources/Module/Buildable")
    }

    @Test("test description with forbidden buildable folders for groups returns expected message")
    func test_description_WithForbiddenBuildableFoldersForGroups_returnsExpectedMessage() {
        // Given
        let groups = ["GroupA", "GroupB", "GroupC"]
        let sut = XcodeProjectParserError.forbiddenBuildableFoldersForGroups(groups)

        // When
        let message = sut.description

        // Then
        let expected = "❌ Forbidden buildable folders for groups: \nGroupA, \nGroupB, \nGroupC"
        #expect(message == expected)
    }

    @Test("test description with forbidden buildable folders for empty groups returns expected message")
    func test_description_WithForbiddenBuildableFoldersForEmptyGroups_returnsExpectedMessage() {
        // Given
        let groups: [String] = []
        let sut = XcodeProjectParserError.forbiddenBuildableFoldersForGroups(groups)

        // When
        let message = sut.description

        // Then
        let expected = "❌ Forbidden buildable folders for groups: \n"
        #expect(message == expected)
    }

    @Test("test description with exception set target is nil returns expected message")
    func test_description_WithExceptionSetTargetIsNil_returnsExpectedMessage() {
        // Given
        let groupPath = "Sources/Group/Path"
        let sut = XcodeProjectParserError.exceptionSetTargetIsNil(groupPath)

        // When
        let message = sut.description

        // Then
        #expect(message == "❌ Exception set target is nil for group at path: Sources/Group/Path")
    }

    @Test("test description with exception set target product type is nil returns expected message")
    func test_description_WithExceptionSetTargetProductTypeIsNil_returnsExpectedMessage() {
        // Given
        let groupPath = "Sources/Group/AnotherPath"
        let sut = XcodeProjectParserError.exceptionSetTargetProductTypeIsNil(groupPath)

        // When
        let message = sut.description

        // Then
        #expect(message == "❌ Exception set target product type is nil for group at path: Sources/Group/AnotherPath")
    }

    // MARK: - Equatable
    @Test("test equatable identical invalidTargetName cases are equal")
    func test_equatable_WithSameInvalidTargetName_returnsEqual() {
        // Given
        let first = XcodeProjectParserError.invalidTargetName("Name")
        let second = XcodeProjectParserError.invalidTargetName("Name")

        // Then
        #expect(first == second)
    }

    @Test("test equatable different invalidTargetName cases not equal")
    func test_equatable_WithDifferentInvalidTargetName_returnsNotEqual() {
        // Given
        let first = XcodeProjectParserError.invalidTargetName("NameA")
        let second = XcodeProjectParserError.invalidTargetName("NameB")

        // Then
        #expect(first != second)
    }

    @Test("test equatable different error cases not equal")
    func test_equatable_WithDifferentCases_returnsNotEqual() {
        // Given
        let first = XcodeProjectParserError.invalidPath("Path")
        let second = XcodeProjectParserError.exceptionSetTargetIsNil("Path")

        // Then
        #expect(first != second)
    }
}
