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
                    "TargetA": [
                        "Sources/TargetA"
                    ],
                    "TargetB": [
                        "Sources/TargetB"
                    ]
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
                    "Sources/Forbidden"
                ],
                files: [
                    "Sources/Forbidden/DoNotUse.swift"
                ]
            )
        ]
    )
}
