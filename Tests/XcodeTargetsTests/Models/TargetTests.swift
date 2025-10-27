@testable import XcodeTargets
import Testing

@Suite("Target Tests")
struct TargetTests {

    @Test("test containsNotEmptySets given only filePaths returns true")
    func test_ContainsNotEmptySetsGivenOnlyFilePathsReturnsTrue() {
        // Given
        let sut = Target(
            name: "App",
            filePaths: [
                "Sources/App/AppDelegate.swift",
                "Sources/App/SceneDelegate.swift"
            ],
            dependencies: [],
            frameworks: []
        )

        // When
        let result = sut.containsNotEmptySets

        // Then
        #expect(result == true)
    }

    @Test("test containsNotEmptySets given only dependencies returns true")
    func test_ContainsNotEmptySetsGivenOnlyDependenciesReturnsTrue() {
        // Given
        let sut = Target(
            name: "App",
            filePaths: [],
            dependencies: [
                "Core",
                "UI"
            ],
            frameworks: []
        )

        // When
        let result = sut.containsNotEmptySets

        // Then
        #expect(result == true)
    }

    @Test("test containsNotEmptySets given only frameworks returns true")
    func test_ContainsNotEmptySetsGivenOnlyFrameworksReturnsTrue() {
        // Given
        let sut = Target(
            name: "App",
            filePaths: [],
            dependencies: [],
            frameworks: [
                "UIKit",
                "Foundation"
            ]
        )

        // When
        let result = sut.containsNotEmptySets

        // Then
        #expect(result == true)
    }

    @Test("test containsNotEmptySets given empty sets returns false")
    func test_ContainsNotEmptySetsGivenEmptySetsReturnsFalse() {
        // Given
        let sut = Target(
            name: "App",
            filePaths: [],
            dependencies: [],
            frameworks: []
        )

        // When
        let result = sut.containsNotEmptySets

        // Then
        #expect(result == false)
    }

    @Test("test differenceTarget given empty dictionary returns empty difference target")
    func test_DifferenceTargetGivenEmptyDictionaryReturnsEmptyDifferenceTarget() throws {
        // Given
        let dictionary: [String: Target] = [:]

        // When
        let result = dictionary.differenceTarget()

        // Then
        let expected = Target(
            name: "Difference",
            filePaths: [],
            dependencies: [],
            frameworks: []
        )
        #expect(result == expected)
    }

    @Test("test differenceTarget given single element dictionary returns empty difference target")
    func test_DifferenceTargetGivenSingleElementDictionaryReturnsEmptyDifferenceTarget() throws {
        // Given
        let dictionary: [String: Target] = [
            "A": Target(
                name: "A",
                filePaths: ["A.swift"],
                dependencies: ["Core"],
                frameworks: ["UIKit"]
            )
        ]

        // When
        let result = dictionary.differenceTarget()

        // Then
        let expected = Target(
            name: "Difference",
            filePaths: [],
            dependencies: [],
            frameworks: []
        )
        #expect(result == expected)
    }

    @Test("test differenceTarget given files and dependencies differ targets returns correct difference target")
    func test_DifferenceTargetGivenDependenciesDifferTargetsReturnsCorrectDifferenceTarget() {
        // Given
        let dictionary: [String: Target] = [
            "A": Target(
                name: "A",
                filePaths: ["A.swift"],
                dependencies: ["Core"],
                frameworks: ["UIKit"]
            ),
            "B": Target(
                name: "B",
                filePaths: ["B.swift"],
                dependencies: ["Core", "Networking"],
                frameworks: ["UIKit"]
            )
        ]

        // When
        let result = dictionary.differenceTarget()

        // Then
        let expected = Target(
            name: "Difference",
            filePaths: ["A.swift", "B.swift"],
            dependencies: ["Networking"],
            frameworks: []
        )
        #expect(result == expected)
    }

    @Test("test differenceTarget given frameworks partly shared returns correct difference target")
    func test_DifferenceTargetGivenFrameworksPartlySharedReturnsCorrectDifferenceTarget() {
        // Given
        let dictionary: [String: Target] = [
            "App": Target(
                name: "App",
                filePaths: ["App.swift"],
                dependencies: [],
                frameworks: ["UIKit", "Combine"]
            ),
            "Widget": Target(
                name: "Widget",
                filePaths: ["Widget.swift"],
                dependencies: [],
                frameworks: ["UIKit"]
            )
        ]

        // When
        let result = dictionary.differenceTarget()

        // Then
        let expected = Target(
            name: "Difference",
            filePaths: ["App.swift", "Widget.swift"],
            dependencies: [],
            frameworks: ["Combine"]
        )
        #expect(result == expected)
    }

    @Test("test differenceTarget given 3 targets with all differing returns correct difference target")
    func test_DifferenceTargetGiven3TargetsWithAllDifferingReturnsCorrectDifferenceTarget() {
        // Given
        let dictionary: [String: Target] = [
            "A": Target(
                name: "A",
                filePaths: ["A.swift", "B.swift"],
                dependencies: ["Core"],
                frameworks: ["UIKit", "Combine"]
            ),
            "B": Target(
                name: "B",
                filePaths: ["B.swift"],
                dependencies: ["Core", "Networking"],
                frameworks: ["Foundation", "Combine"]
            ),
            "C": Target(
                name: "C",
                filePaths: ["B.swift", "C.swift"],
                dependencies: ["UI", "Core"],
                frameworks: ["Combine"]
            )
        ]

        // When
        let result = dictionary.differenceTarget()

        // Then
        let expected = Target(
            name: "Difference",
            filePaths: ["A.swift", "C.swift"],
            dependencies: ["Networking", "UI"],
            frameworks: ["UIKit", "Foundation"]
        )
        #expect(result == expected)
    }
}
