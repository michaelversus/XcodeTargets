@testable import XcodeTargets

extension TargetModel {
    static let empty = TargetModel(
        name: "",
        buildableFilePaths: [],
        sourceFilePaths: [],
        resourceFilePaths: [],
        dependencies: [],
        frameworks: []
    )
}
