@testable import XcodeTargets
import Testing

@Suite("TargetModel Tests")
struct TargetModelTests {

    @Test("tet init")
    func test_init() {
        // Given
        let sut = TargetModel(
            name: "TargetA",
            buildableFilePaths: ["Sources/TargetA/FileA.swift"],
            sourceFilePaths: ["Sources/TargetA/FileB.swift"],
            resourceFilePaths: ["Resources/TargetA/Image.png"],
            dependencies: ["TargetB"],
            frameworks: ["UIKit"]
        )

        // Then
        #expect(sut.name == "TargetA")
        #expect(sut.buildableFilePaths == ["Sources/TargetA/FileA.swift"])
        #expect(sut.sourceFilePaths == ["Sources/TargetA/FileB.swift"])
        #expect(sut.resourceFilePaths == ["Resources/TargetA/Image.png"])
        #expect(sut.dependencies == ["TargetB"])
        #expect(sut.frameworks == ["UIKit"])
        let expectedFilePaths: Set<String> = [
            "Sources/TargetA/FileA.swift",
            "Sources/TargetA/FileB.swift",
            "Resources/TargetA/Image.png"
        ]
        #expect(sut.filePaths == expectedFilePaths)
    }

    @Test("test mappingToTarget")
    func test_mappingToTarget() async throws {
        // Given
        let sut = TargetModel(
            name: "TargetA",
            buildableFilePaths: ["Sources/TargetA/FileA.swift"],
            sourceFilePaths: ["Sources/TargetA/FileB.swift"],
            resourceFilePaths: ["Resources/TargetA/Image.png"],
            dependencies: ["TargetB"],
            frameworks: ["UIKit"]
        )

        // When
        let target = sut.mappingToTarget()

        // Then
        let expectedTarget = Target(
            name: "TargetA",
            filePaths: [
                "Sources/TargetA/FileA.swift",
                "Sources/TargetA/FileB.swift",
                "Resources/TargetA/Image.png"
            ],
            dependencies: ["TargetB"],
            frameworks: ["UIKit"]
        )
        #expect(target == expectedTarget)
    }

    @Test("test insertingBuildableFilePath")
    func test_insertingBuildableFilePath() {
        // Given
        let sut = TargetModel(
            name: "TargetA",
            buildableFilePaths: ["Sources/TargetA/FileA.swift"],
            sourceFilePaths: ["Sources/TargetA/FileB.swift"],
            resourceFilePaths: ["Resources/TargetA/Image.png"],
            dependencies: ["TargetB"],
            frameworks: ["UIKit"]
        )

        // When
        let newSut = sut.insertingBuildableFilePath("Sources/TargetA/FileC.swift")

        // Then
        let expectedTargetModel = TargetModel(
            name: "TargetA",
            buildableFilePaths: [
                "Sources/TargetA/FileA.swift",
                "Sources/TargetA/FileC.swift"
            ],
            sourceFilePaths: ["Sources/TargetA/FileB.swift"],
            resourceFilePaths: ["Resources/TargetA/Image.png"],
            dependencies: ["TargetB"],
            frameworks: ["UIKit"]
        )
        #expect(newSut == expectedTargetModel)
    }

    @Test("test dictionary insert buildableFilePaths forTargets")
    func test_dictionary_insert_buildableFilePaths_forTargets() {
        // Given
        var sut: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: ["Sources/TargetA/FileA.swift"],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            )
        ]
        let pathsToInsert: Set<String> = [
            "Sources/Shared/File1.swift",
            "Sources/Shared/File2.swift"
        ]
        let targetNamesToInsert: Set<String> = [
            "TargetA",
            "TargetB"
        ]

        // When
        sut.insert(buildableFilePaths: pathsToInsert, forTargets: targetNamesToInsert)

        // Then
        let expectedSut: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: [
                    "Sources/TargetA/FileA.swift",
                    "Sources/Shared/File1.swift",
                    "Sources/Shared/File2.swift"
                ],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            ),
            "TargetB": TargetModel(
                name: "TargetB",
                buildableFilePaths: [
                    "Sources/Shared/File1.swift",
                    "Sources/Shared/File2.swift"
                ],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            )
        ]
        #expect(sut == expectedSut)
    }

    @Test("test dictionary insert sourceFilePaths forTargets")
    func test_dictionary_insert_sourceFilePaths_forTargets() {
        // Given
        var sut: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: [],
                sourceFilePaths: ["Sources/TargetA/FileA.swift"],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            )
        ]
        let pathsToInsert: Set<String> = [
            "Sources/Shared/File1.swift",
            "Sources/Shared/File2.swift"
        ]
        let targetNamesToInsert: Set<String> = [
            "TargetA",
            "TargetB"
        ]

        // When
        sut.insert(sourceFilePaths: pathsToInsert, forTargets: targetNamesToInsert)

        // Then
        let expectedSut: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: [],
                sourceFilePaths: [
                    "Sources/TargetA/FileA.swift",
                    "Sources/Shared/File1.swift",
                    "Sources/Shared/File2.swift"
                ],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            ),
            "TargetB": TargetModel(
                name: "TargetB",
                buildableFilePaths: [],
                sourceFilePaths: [
                    "Sources/Shared/File1.swift",
                    "Sources/Shared/File2.swift"
                ],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            )
        ]
        #expect(sut == expectedSut)
    }

    @Test("test dictionary insert resourceFilePaths forTargets")
    func test_dictionary_insert_resourceFilePaths_forTargets() {
        // Given
        var sut: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: [],
                sourceFilePaths: [],
                resourceFilePaths: ["Resources/TargetA/ImageA.png"],
                dependencies: [],
                frameworks: []
            )
        ]
        let pathsToInsert: Set<String> = [
            "Resources/Shared/Image1.png",
            "Resources/Shared/Image2.png"
        ]
        let targetNamesToInsert: Set<String> = [
            "TargetA",
            "TargetB"
        ]

        // When
        sut.insert(resourceFilePaths: pathsToInsert, forTargets: targetNamesToInsert)

        // Then
        let expectedSut: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: [],
                sourceFilePaths: [],
                resourceFilePaths: [
                    "Resources/TargetA/ImageA.png",
                    "Resources/Shared/Image1.png",
                    "Resources/Shared/Image2.png"
                ],
                dependencies: [],
                frameworks: []
            ),
            "TargetB": TargetModel(
                name: "TargetB",
                buildableFilePaths: [],
                sourceFilePaths: [],
                resourceFilePaths: [
                    "Resources/Shared/Image1.png",
                    "Resources/Shared/Image2.png"
                ],
                dependencies: [],
                frameworks: []
            )
        ]
        #expect(sut == expectedSut)
    }

    @Test("test dictionary printSummary given targetModel with all properties non empty")
    func test_dictionary_printSummary_given_targetModel_with_all_properties_non_empty() {
        // Given
        let sut: [String: TargetModel] = [
            "TargetB": TargetModel(
                name: "TargetB",
                buildableFilePaths: [],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            ),
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: ["FileA.swift", "FileB.swift"],
                sourceFilePaths: ["FileC.swift", "FileD.swift"],
                resourceFilePaths: [
                    "Resources/TargetA/Image.png",
                    "Resources/TargetA/Data.json"
                ],
                dependencies: ["TargetB", "TargetC"],
                frameworks: ["UIKit", "Foundation"]
            )
        ]
        var messages: [String] = []
        let print: (String) -> Void = { message in
            messages.append(message)
        }

        // When
        sut.printSummary(print: print, vPrint: print)

        // Then
        let expectedMessages: [String] = [
            "Target: TargetA total files: 6",
            "  Buildable files: 2",
            "TargetA - FileA.swift",
            "TargetA - FileB.swift",
            "  Source files: 2",
            "TargetA - FileC.swift",
            "TargetA - FileD.swift",
            "  Resource files: 2",
            "TargetA - Resources/TargetA/Data.json",
            "TargetA - Resources/TargetA/Image.png",
            "  Dependencies: 2",
            "TargetA - TargetB",
            "TargetA - TargetC",
            "  Frameworks: 2",
            "TargetA - Foundation",
            "TargetA - UIKit",
            "Target: TargetB total files: 0",
            "  Buildable files: 0",
            "  Source files: 0",
            "  Resource files: 0",
            "  Dependencies: 0",
            "  Frameworks: 0"
        ]
        #expect(messages == expectedMessages)
    }
}
