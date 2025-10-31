import Foundation

/// Processes exclusive entries (files, dependencies, frameworks) across groups of targets defined in a `Configuration`.
///
/// Phase 1: Prunes any entries declared as exclusive for a target.
/// Phase 2: Validates that after pruning, no residual exclusive differences remain among grouped targets. If differences are still present it throws `ExclusivesError.exclusiveEntriesFound`.
///
/// Verbose diagnostic lines are emitted through the injected `print` closure when residual exclusives are detected.
struct ExclusivesProcessor {
    /// Result of processing exclusive entries containing the pruned concrete `Target` models indexed by target name.
    struct Result {
        let prunedTargets: [String: Target]
    }

    /// Closure used for verbose logging of exclusive entry diagnostics.
    let print: (String) -> Void

    /// Initializes an instance.
    /// - Parameter print: Closure invoked with human readable diagnostic messages.
    init(print: @escaping (String) -> Void) {
        self.print = print
    }

    /// Prunes exclusive entries and validates no residual exclusives remain.
    /// - Parameters:
    ///   - configuration: The configuration containing file membership sets and exclusives definitions.
    ///   - originalTargetsIndex: Mapping of target names to their `TargetModel` representations prior to pruning.
    /// - Returns: A `Result` containing pruned concrete `Target` models.
    /// - Throws: `ExclusivesError.invalidTargetName` if an exclusive references a missing target.
    ///           `ExclusivesError.invalidPathForTarget` if an exclusive path pattern matches nothing.
    ///           `ExclusivesError.exclusiveEntriesFound` if differences remain after pruning.
    @discardableResult
    func process(
        configuration: Configuration,
        originalTargetsIndex: [String: TargetModel]
    ) throws -> Result {
        // Map initial index to concrete Target models (once).
        var workingTargets = originalTargetsIndex.mapValues {  $0.mappingToTarget() }
        // 1. Prune exclusives.
        workingTargets = try pruneExclusiveEntries(
            in: workingTargets,
            fileMembershipSets: configuration.fileMembershipSets
        )

        // 2. Validate no residual exclusives remain among grouped targets.
        try validateNoResidualExclusives(
            workingTargets: workingTargets,
            fileMembershipSets: configuration.fileMembershipSets
        )

        return Result(
            prunedTargets: workingTargets
        )
    }
}

private extension ExclusivesProcessor {
    func pruneExclusiveEntries(
        in targetsIndex: [String: Target],
        fileMembershipSets: [Configuration.FileMembershipSet]
    ) throws -> [String: Target] {
        var mutableTargetsIndex = targetsIndex
        for fileMembershipSet in fileMembershipSets {
            guard let exclusive = fileMembershipSet.exclusive else { continue }
            for (targetName, targetExclusive) in exclusive {
                guard var target = mutableTargetsIndex[targetName] else {
                    throw ExclusivesError.invalidTargetName(targetName)
                }
                if let files = targetExclusive.files {
                    target.filePaths = try pruneCollection(
                        source: target.filePaths,
                        exclusives: files,
                        targetName: targetName,
                        matchStrategy: fileMatchStrategy
                    )
                }
                if let dependencies = targetExclusive.dependencies {
                    target.dependencies = try pruneCollection(
                        source: target.dependencies,
                        exclusives: dependencies,
                        targetName: targetName,
                        matchStrategy: exactOrContains
                    )
                }
                if let frameworks = targetExclusive.frameworks {
                    target.frameworks = try pruneCollection(
                        source: target.frameworks,
                        exclusives: frameworks,
                        targetName: targetName,
                        matchStrategy: exactOrContains
                    )
                }
                mutableTargetsIndex[targetName] = target
            }
        }
        return mutableTargetsIndex
    }

    func pruneCollection(
        source: Set<String>,
        exclusives: [String],
        targetName: String,
        matchStrategy: (Set<String>, String) -> Set<String>
    ) throws -> Set<String> {
        var pruned = source
        for exclusive in exclusives {
            let matched = matchStrategy(pruned, exclusive)
            if matched.isEmpty {
                throw ExclusivesError.invalidPathForTarget(targetName: targetName, path: exclusive)
            }
            pruned = pruned.subtracting(matched)
        }
        return pruned
    }

    /// Handles wildcard patterns path/* and path/.* (directory contents) otherwise substring containment.
    func fileMatchStrategy(source: Set<String>, pattern: String) -> Set<String> {
        let isWildcard = pattern.hasSuffix("/*") || pattern.hasSuffix("/.*")
        if isWildcard {
            let directory = pattern.dropWildCards()
            return source.filter { $0.contains(directory) }
        } else {
            return source.filter { $0.contains(pattern) }
        }
    }

    /// Simple containment strategy (could be replaced with exact match if required).
    func exactOrContains(source: Set<String>, pattern: String) -> Set<String> {
        let direct = source.filter { $0 == pattern }
        if !direct.isEmpty { return direct }
        return source.filter { $0.contains(pattern) }
    }

    // MARK: - Validation

    func validateNoResidualExclusives(
        workingTargets: [String: Target],
        fileMembershipSets: [Configuration.FileMembershipSet]
    ) throws {
        for set in fileMembershipSets {
            let names = set.targets
            let slice = workingTargets.filter { names.contains($0.key) }
            let diff = slice.differenceTarget()
            let joined = names.joined(separator: ", ")

            logIfNotEmpty(kind: "files", entries: diff.filePaths, targets: joined)
            logIfNotEmpty(kind: "dependencies", entries: diff.dependencies, targets: joined)
            logIfNotEmpty(kind: "frameworks", entries: diff.frameworks, targets: joined)

            if diff.containsNotEmptySets {
                throw ExclusivesError.exclusiveEntriesFound(targetNames: joined)
            }
        }
    }

    func logIfNotEmpty(
        kind: String,
        entries: Set<String>,
        targets: String
    ) {
        guard !entries.isEmpty else { return }
        print("error: ❌ Exclusive \(kind) found between targets \(targets):")
        for entry in entries.sorted() {
            print(" - \(entry)")
        }
    }
}
