import Testing
@testable import XcodeTargets

@Suite("ForbiddenResourcesProcessor Tests")
final class ForbiddenResourcesProcessorTests {

    var messages: [String] = []
    lazy var vPrint: (String) -> Void = { [weak self] message in
        self?.messages.append(message)
    }

    @Test("test process forbidden resources given empty forbiddenResourceSets")
    func testProcessForbiddenResourcesGivenEmptyForbiddenResourceSets() throws {
        // Given
        let configuration = Configuration.empty
        let targetsIndex = [
            "TargetA": TargetModel.empty
        ]
        let sut = makeSut()

        // When
        try sut.process(
            configuration: configuration,
            targetsIndex: targetsIndex
        )

        // Then
        #expect(messages.isEmpty)
    }

    @Test("test process forbidden resources given forbidden resources without targets")
    func testProcessForbiddenResourcesGivenForbiddenResourcesWithoutTargets() throws {
        // Given
        let configuration = Configuration(
            name: "Example",
            fileMembershipSets: [],
            forbiddenResourceSets: [
                .init(
                    targets: [],
                    paths: [
                        "Sources/Forbidden"
                    ]
                )
            ],
            duplicatesValidationExcludedTargets: []
        )
        let targetsIndex = [
            "TargetA": TargetModel.empty
        ]
        let sut = makeSut()

        // When
        try sut.process(
            configuration: configuration,
            targetsIndex: targetsIndex
        )

        // Then
        let expectedMessage = "Warning: Forbidden resource set has no targets defined, skipping."
        #expect(messages == [expectedMessage])
    }

    @Test("test process forbidden resources given valid forbidden resources but target not found in targets index")
    func testProcessForbiddenResourcesGivenValidForbiddenResourcesButTargetNotFoundInTargetsIndex() throws {
        // Given
        let configuration = Configuration(
            name: "Example",
            fileMembershipSets: [],
            forbiddenResourceSets: [
                .init(
                    targets: ["TargetB"],
                    paths: [
                        "Sources/Forbidden"
                    ]
                )
            ],
            duplicatesValidationExcludedTargets: []
        )
        let targetsIndex = [
            "TargetA": TargetModel.empty
        ]
        let sut = makeSut()

        // When
        try sut.process(
            configuration: configuration,
            targetsIndex: targetsIndex
        )

        // Then
        let expectedMessages = [
            "Processing forbidden resource set for targets: TargetB",
            "Warning: Target TargetB not found in targets index."
        ]
        #expect(messages == expectedMessages)
    }

    @Test("test process forbidden resources given forbidden resources not found in target")
    func testProcessForbiddenResourcesGivenForbiddenResourcesNotFoundInTarget() throws {
        // Given
        let configuration = Configuration(
            name: "Example",
            fileMembershipSets: [],
            forbiddenResourceSets: [
                .init(
                    targets: ["TargetA"],
                    paths: [
                        "Sources/Forbidden"
                    ]
                )
            ],
            duplicatesValidationExcludedTargets: []
        )
        let targetsIndex = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: ["Sources/Allowed/File.swift"],
                sourceFilePaths: ["Sources/Allowed/FileA.swift"],
                resourceFilePaths: ["Resources/Image.png"],
                dependencies: [],
                frameworks: []
            )
        ]
        let sut = makeSut()

        // When
        try sut.process(
            configuration: configuration,
            targetsIndex: targetsIndex
        )

        // Then
        let expectedMessages = [
            "Processing forbidden resource set for targets: TargetA",
            "No forbidden resources found in target TargetA for path Sources/Forbidden."
        ]
        #expect(messages == expectedMessages)
    }

    @Test("test process forbidden resources given forbidden resources found in target")
    func testProcessForbiddenResourcesGivenForbiddenResourcesFoundInTarget() throws {
        // Given
        let configuration = Configuration(
            name: "Example",
            fileMembershipSets: [],
            forbiddenResourceSets: [
                .init(
                    targets: ["TargetA"],
                    paths: [
                        "Sources/Forbidden"
                    ]
                )
            ],
            duplicatesValidationExcludedTargets: []
        )
        let targetsIndex = [
            "TargetA": TargetModel(
                name: "TargetA",
                buildableFilePaths: ["Sources/Allowed/File.swift"],
                sourceFilePaths: ["Sources/Allowed/FileA.swift"],
                resourceFilePaths: ["Sources/Forbidden/Resources/Image.png"],
                dependencies: [],
                frameworks: []
            )
        ]
        let sut = makeSut()

        // When
        let error = #expect(throws: ForbiddenResourceError.self, performing: {
            try sut.process(
                configuration: configuration,
                targetsIndex: targetsIndex
            )
        })


        // Then
        let expectedMessages = [
            "Processing forbidden resource set for targets: TargetA"
        ]
        let expectedError = ForbiddenResourceError(
            targetName: "TargetA",
            matchingPaths: ["Sources/Forbidden/Resources/Image.png"]
        )
        #expect(messages == expectedMessages)
        #expect(error == expectedError)
    }
}

private extension ForbiddenResourcesProcessorTests {

    func makeSut() -> ForbiddenResourcesProcessor {
        ForbiddenResourcesProcessor(vPrint: vPrint)
    }
}
