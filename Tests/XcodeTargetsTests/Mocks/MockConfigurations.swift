import Foundation
@testable import XcodeTargets

extension Configuration {
    static let mock = Configuration(
        name: "Example",
        fileMembershipSets: [
            .init(
                targets: [
                    "TargetA",
                    "TargetB"
                ],
                exclusive: [
                    "TargetA": TargetExclusive(
                        files: ["Sources/TargetA"],
                        dependencies: [],
                        frameworks: []
                    ),
                    "TargetB": TargetExclusive(
                        files: ["Sources/TargetB"],
                        dependencies: [],
                        frameworks: []
                    )
                ]
            )
        ],
        forbiddenResourceSets: [
            .init(
                targets: [
                    "TargetA",
                    "TargetB"
                ],
                paths: [
                    "Sources/Forbidden",
                    "Sources/Forbidden/DoNotUse.swift"
                ]
            )
        ],
        duplicatesValidationExcludedTargets: []
    )

    static let empty = Configuration(
        name: "Empty",
        fileMembershipSets: [],
        forbiddenResourceSets: nil,
        duplicatesValidationExcludedTargets: nil
    )
}
