import Foundation

struct Target: Equatable {
    let name: String
    var filePaths: Set<String>
    var dependencies: Set<String>
    var frameworks: Set<String>
}

extension Target {
    var containsNotEmptySets: Bool {
        !filePaths.isEmpty || !dependencies.isEmpty || !frameworks.isEmpty
    }
}

// MARK: - Difference Target computation
extension Dictionary where Key == String, Value == Target {
    /// Builds a synthetic `Target` whose sets contain only the elements that are **not common to all** targets
    /// in the dictionary.
    ///
    /// For each property (`filePaths`, `dependencies`, `frameworks`):
    /// 1. Compute the union of all sets (every element that appears at least once).
    /// 2. Compute the intersection of all sets (every element that appears in **every** target).
    /// 3. Return `union − intersection`, i.e. the elements that are present in at least one target but **not** in all.
    ///
    /// This lets you quickly see what varies across a collection of targets (the "differences") while omitting
    /// the completely shared core.
    ///
    /// Notes:
    /// - If the dictionary is empty, an empty `Target` is returned.
    /// - If all targets have identical sets for a property, that property's resulting set will be empty.
    /// - This is **not** a symmetric difference pairwise; it specifically removes elements common to *all* targets.
    ///
    /// - Parameter name: Optional name for the resulting target (default: "Difference").
    /// - Returns: A `Target` whose sets contain only non-universally-shared elements.
    ///
    /// Example 1 (dependencies differ):
    /// ```swift
    /// let t1 = Target(name: "A", filePaths: ["A.swift"], dependencies: ["Core"], frameworks: ["UIKit"])
    /// let t2 = Target(name: "B", filePaths: ["B.swift"], dependencies: ["Core", "Networking"], frameworks: ["UIKit"])
    /// let dict: [String: Target] = ["A": t1, "B": t2]
    /// let diff = dict.differenceTarget()
    /// // diff.filePaths = ["A.swift", "B.swift"] (each appears only in one target)
    /// // diff.dependencies = ["Networking"] ("Core" is shared by all → removed)
    /// // diff.frameworks = [] ("UIKit" shared by all → removed)
    /// ```
    ///
    /// Example 2 (frameworks partly shared):
    /// ```swift
    /// let t1 = Target(name: "App", filePaths: ["App.swift"], dependencies: [], frameworks: ["UIKit", "Combine"])
    /// let t2 = Target(name: "Widget", filePaths: ["Widget.swift"], dependencies: [], frameworks: ["UIKit"])
    /// let dict: [String: Target] = ["App": t1, "Widget": t2]
    /// let diff = dict.differenceTarget(named: "VaryingPieces")
    /// // diff.name == "VaryingPieces"
    /// // diff.filePaths = ["App.swift", "Widget.swift"]
    /// // diff.dependencies = []
    /// // diff.frameworks = ["Combine"] (only in App; "UIKit" shared and removed)
    /// ```
    func differenceTarget(named name: String = "Difference") -> Target {
        guard count > 1 else {
            return Target(
                name: name,
                filePaths: [],
                dependencies: [],
                frameworks: []
            )
        }
        let targets = Array(values)

        func difference(_ keyPath: KeyPath<Target, Set<String>>) -> Set<String> {
            let sets = targets.map { $0[keyPath: keyPath] }
            // Union
            let union = sets.reduce(into: Set<String>()) { $0.formUnion($1) }
            // Intersection
            let intersection = sets.dropFirst().reduce(sets.first ?? Set<String>()) { $0.intersection($1) }
            // Elements that are not in all sets
            return union.subtracting(intersection)
        }

        return Target(
            name: name,
            filePaths: difference(\.filePaths),
            dependencies: difference(\.dependencies),
            frameworks: difference(\.frameworks)
        )
    }
}
