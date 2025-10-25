import Foundation

struct ForbiddenResourcesProcessor {
    struct ForbiddenResourceError: LocalizedError {
        let targetName: String
        let matchingPaths: Set<String>

        var errorDescription: String {
            "❌ Forbidden resource(s) found in target \(targetName):\n" +
            matchingPaths
                .map { " - \($0)" }
                .sorted()
                .joined(separator: "\n")
        }
    }

    let vPrint: (String) -> Void

    init(vPrint: @escaping (String) -> Void) {
        self.vPrint = vPrint
    }

    func process(
        configuration: Configuration,
        targetsIndex: [String: TargetModel]
    ) throws {
        for forbiddenResourceSet in configuration.forbiddenResourceSets ?? [] {
            vPrint("Processing forbidden resource set for targets: \(forbiddenResourceSet.targets)")

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
                    }
                }
            }
        }
    }
}
