import Foundation

// MARK: - ForbiddenResourcesProcessor

/// Coordinates validation of forbidden resource paths across configured targets.
/// Supply a lightweight logging closure `vPrint` to capture verbose diagnostic messages.
/// The processor iterates each forbidden resource set, checks listed target resource file paths, and
/// throws immediately on the first violation encountered.
struct ForbiddenResourcesProcessor {
    /// Verbose logging closure used to emit progress messages and non-fatal warnings during processing.
    /// Provide a no-op implementation when verbose output is not desired.
    let vPrint: (String) -> Void

    /// Creates a new processor.
    /// - Parameter vPrint: Closure used for verbose logging of progress and non-fatal warnings.
    init(vPrint: @escaping (String) -> Void) {
        self.vPrint = vPrint
    }

    /// Processes all forbidden resource sets defined in the provided configuration, validating that
    /// none of the listed targets contain resource file paths matching any forbidden path substring.
    ///
    /// The method iterates each forbidden resource set. For every target name in the set:
    /// - If the target does not exist in `targetsIndex`, a warning is logged and the target is skipped.
    /// - Each forbidden path substring is matched against the target's `resourceFilePaths` using simple
    ///   containment (`String.contains`). On the first match, a `ForbiddenResourceError` is thrown.
    ///
    /// - Parameters:
    ///   - configuration: The configuration containing zero or more forbidden resource sets.
    ///   - targetsIndex: Dictionary mapping target names to their `TargetModel` for resource lookup.
    /// - Throws: `ForbiddenResourceError` if a target includes at least one forbidden resource path.
    /// - Note: A forbidden resource set with no targets triggers a warning and is skipped. Missing
    ///         targets also trigger warnings without failing the entire process.
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
