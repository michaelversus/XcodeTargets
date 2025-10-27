import Foundation

struct ForbiddenResourcesProcessor {
    let vPrint: (String) -> Void

    init(vPrint: @escaping (String) -> Void) {
        self.vPrint = vPrint
    }

    func process(
        configuration: Configuration,
        targetsIndex: [String: TargetModel]
    ) throws {
        for forbiddenResourceSet in configuration.forbiddenResourceSets ?? [] {
            guard !forbiddenResourceSet.targets.isEmpty else {
                vPrint("Warning: Forbidden resource set has no targets defined, skipping.")
                continue
            }
            let processingTargetsString = forbiddenResourceSet.targets.joined(separator: ", ")
            vPrint("Processing forbidden resource set for targets: \(processingTargetsString)")

            for targetName in forbiddenResourceSet.targets {
                guard let target = targetsIndex[targetName] else {
                    vPrint("Warning: Target \(targetName) not found in targets index.")
                    continue
                }

                for forbiddenResourcePath in forbiddenResourceSet.paths ?? [] {
                    let matchingPaths = target.resourceFilePaths.filter { $0.contains(forbiddenResourcePath) }
                    if !matchingPaths.isEmpty {
                        throw ForbiddenResourceError(
                            targetName: targetName,
                            matchingPaths: matchingPaths
                        )
                    } else {
                        vPrint(
                            "No forbidden resources found in target \(targetName) " +
                            "for path \(forbiddenResourcePath)."
                        )
                    }
                }
            }
        }
    }
}
