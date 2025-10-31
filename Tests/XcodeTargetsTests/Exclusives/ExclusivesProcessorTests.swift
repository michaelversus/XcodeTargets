@testable import XcodeTargets
import Testing

@Suite("ExclusivesProcessor Tests")
final class ExclusivesProcessorTests {
    // Captured verbose messages
    var messages: [String] = []
    lazy var print: (String) -> Void = { [weak self] message in
        self?.messages.append(message)
    }

    @Test("test process given empty fileMembershipSets produces identical targets and no messages")
    func testProcessGivenEmptyFileMembershipSetsProducesIdenticalTargetsAndNoMessages() throws {
        // Given
        messages.removeAll()
        let configuration = Configuration.empty
        let originalTargetsIndex: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: ["Sources/Shared/A.swift"],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: ["Core"],
                frameworks: ["UIKit"]
            )
        ]
        let sut = makeSut()

        // When
        let result = try sut.process(
            configuration: configuration,
            originalTargetsIndex: originalTargetsIndex
        )

        // Then
        #expect(messages.isEmpty)
        #expect(result.prunedTargets.count == 1)
        #expect(result.prunedTargets["TargetA"]?.filePaths == ["Sources/Shared/A.swift"])
        #expect(result.prunedTargets["TargetA"]?.dependencies == ["Core"])
        #expect(result.prunedTargets["TargetA"]?.frameworks == ["UIKit"])
    }

    @Test("test process given exclusives prunes target specific entries and leaves shared ones")
    func testProcessGivenExclusivesPrunesTargetSpecificEntriesAndLeavesSharedOnes() throws {
        // Given
        messages.removeAll()
        let configuration = Configuration(
            name: "Example",
            fileMembershipSets: [
                .init(
                    targets: ["TargetA", "TargetB"],
                    exclusive: [
                        "TargetA": .init(
                            files: ["Sources/TargetA"],
                            dependencies: ["Networking"],
                            frameworks: ["Combine"]
                        ),
                        "TargetB": .init(
                            files: ["Sources/TargetB"],
                            dependencies: ["Analytics"],
                            frameworks: []
                        )
                    ]
                )
            ],
            forbiddenResourceSets: nil,
            duplicatesValidationExcludedTargets: nil
        )
        let originalTargetsIndex: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: [
                    "Sources/TargetA/File.swift",
                    "Sources/Common/File.swift"
                ],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: ["CommonKit", "Networking"],
                frameworks: ["UIKit", "Combine"]
            ),
            "TargetB": TargetModel(
                name: "TargetB",
                buildableFilePaths: [
                    "Sources/TargetB/File.swift",
                    "Sources/Common/File.swift"
                ],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: ["CommonKit", "Analytics"],
                frameworks: ["UIKit"]
            )
        ]
        let sut = makeSut()

        // When
        let result = try sut.process(
            configuration: configuration,
            originalTargetsIndex: originalTargetsIndex
        )

        // Then
        #expect(messages.isEmpty, "No residual exclusives should be logged")
        let prunedA = result.prunedTargets["TargetA"]
        let prunedB = result.prunedTargets["TargetB"]
        #expect(prunedA?.filePaths == ["Sources/Common/File.swift"])
        #expect(prunedB?.filePaths == ["Sources/Common/File.swift"])
        #expect(prunedA?.dependencies == ["CommonKit"])
        #expect(prunedB?.dependencies == ["CommonKit"])
        #expect(prunedA?.frameworks == ["UIKit"])
        #expect(prunedB?.frameworks == ["UIKit"])
    }

    @Test("test process given invalid exclusive target name throws invalidTargetName error")
    func testProcessGivenInvalidExclusiveTargetNameThrowsInvalidTargetNameError() throws {
        // Given
        messages.removeAll()
        let configuration = Configuration(
            name: "Example",
            fileMembershipSets: [
                .init(
                    targets: ["TargetA"],
                    exclusive: [
                        "UnknownTarget": .init(
                            files: ["Sources/UnknownTarget"],
                            dependencies: nil,
                            frameworks: nil
                        )
                    ]
                )
            ],
            forbiddenResourceSets: nil,
            duplicatesValidationExcludedTargets: nil
        )
        let originalTargetsIndex: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: ["Sources/TargetA/File.swift"],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            )
        ]
        let sut = makeSut()

        // When / Then
        let error = #expect(throws: ExclusivesError.self, performing: {
            _ = try sut.process(
                configuration: configuration,
                originalTargetsIndex: originalTargetsIndex
            )
        })
        #expect(error == .invalidTargetName("UnknownTarget"))
    }

    @Test("test process given invalid exclusive path throws invalidPathForTarget error")
    func testProcessGivenInvalidExclusivePathThrowsInvalidPathForTargetError() throws {
        // Given
        messages.removeAll()
        let configuration = Configuration(
            name: "Example",
            fileMembershipSets: [
                .init(
                    targets: ["TargetA"],
                    exclusive: [
                        "TargetA": .init(
                            files: ["Sources/DoesNotExist"],
                            dependencies: nil,
                            frameworks: nil
                        )
                    ]
                )
            ],
            forbiddenResourceSets: nil,
            duplicatesValidationExcludedTargets: nil
        )
        let originalTargetsIndex: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: ["Sources/TargetA/File.swift"],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            )
        ]
        let sut = makeSut()

        // When / Then
        let error = #expect(throws: ExclusivesError.self, performing: {
            _ = try sut.process(
                configuration: configuration,
                originalTargetsIndex: originalTargetsIndex
            )
        })
        #expect(error == .invalidPathForTarget(targetName: "TargetA", path: "Sources/DoesNotExist"))
    }

    @Test("test process given residual exclusives after pruning throws exclusiveEntriesFound and logs differences")
    func testProcessGivenResidualExclusivesAfterPruningThrowsExclusiveEntriesFoundAndLogsDifferences() throws {
        // Given
        messages.removeAll()
        let configuration = Configuration(
            name: "Example",
            fileMembershipSets: [
                .init(
                    targets: ["TargetA", "TargetB"],
                    exclusive: [
                        "TargetA": .init(
                            files: ["Sources/TargetA"],
                            dependencies: nil,
                            frameworks: nil
                        ),
                        "TargetB": .init(
                            files: ["Sources/TargetB"],
                            dependencies: nil,
                            frameworks: nil
                        )
                    ]
                )
            ],
            forbiddenResourceSets: nil,
            duplicatesValidationExcludedTargets: nil
        )
        let originalTargetsIndex: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: [
                    "Sources/TargetA/File.swift",
                    "Sources/Shared/File.swift"
                ],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: ["Core", "Networking"],
                frameworks: ["UIKit"]
            ),
            "TargetB": TargetModel(
                name: "TargetB",
                buildableFilePaths: [
                    "Sources/TargetB/File.swift",
                    "Sources/Shared/File.swift"
                ],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: ["Core"],
                frameworks: ["UIKit"]
            )
        ]
        let sut = makeSut()

        // When / Then
        let error = #expect(throws: ExclusivesError.self, performing: {
            _ = try sut.process(
                configuration: configuration,
                originalTargetsIndex: originalTargetsIndex
            )
        })

        // Then
        let diff = Target(
            name: "Difference",
            filePaths: [],
            dependencies: ["Networking"],
            frameworks: []
        )
        #expect(messages.isEmpty)
        #expect(error == .exclusiveEntriesFound(targetNames: "TargetA, TargetB", diff: diff))
    }

    @Test("test process given wildcard exclusive pattern prunes all matching file paths")
    func testProcessGivenWildcardExclusivePatternPrunesAllMatchingFilePaths() throws {
        // Given
        messages.removeAll()
        let configuration = Configuration(
            name: "Example",
            fileMembershipSets: [
                .init(
                    targets: ["TargetA", "TargetB"],
                    exclusive: [
                        "TargetA": .init(
                            files: ["Sources/TargetA/*"],
                            dependencies: nil,
                            frameworks: nil
                        ),
                        "TargetB": .init(
                            files: ["Sources/TargetB/.*"],
                            dependencies: nil,
                            frameworks: nil
                        )
                    ]
                )
            ],
            forbiddenResourceSets: nil,
            duplicatesValidationExcludedTargets: nil
        )
        let originalTargetsIndex: [String: TargetModel] = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: [
                    "Sources/TargetA/Source1.swift",
                    "Sources/TargetA/Sub/Source2.swift",
                    "Sources/Shared/File.swift"
                ],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: ["Core"],
                frameworks: []
            ),
            "TargetB": TargetModel(
                name: "TargetB",
                buildableFilePaths: [
                    "Sources/TargetB/Resource.png",
                    "Sources/TargetB/Sub/Resource2.png",
                    "Sources/Shared/File.swift"
                ],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: ["Core"],
                frameworks: []
            )
        ]
        let sut = makeSut()

        // When
        let result = try sut.process(
            configuration: configuration,
            originalTargetsIndex: originalTargetsIndex
        )

        // Then
        #expect(messages.isEmpty)
        #expect(result.prunedTargets["TargetA"]?.filePaths == ["Sources/Shared/File.swift"])
        #expect(result.prunedTargets["TargetB"]?.filePaths == ["Sources/Shared/File.swift"])
    }
}

private extension ExclusivesProcessorTests {
    func makeSut() -> ExclusivesProcessor {
        ExclusivesProcessor(print: print)
    }
}
