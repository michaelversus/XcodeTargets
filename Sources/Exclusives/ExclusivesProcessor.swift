import Foundation

struct ExclusivesProcessor {
    struct Result {
        let prunedTargets: [String: Target]
    }

    let vPrint: (String) -> Void

    init(vPrint: @escaping (String) -> Void) {
        self.vPrint = vPrint
    }

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
        vPrint("Exclusive \(kind) found between targets \(targets):")
        for entry in entries.sorted() {
            vPrint(" - \(entry)")
        }
    }
}
