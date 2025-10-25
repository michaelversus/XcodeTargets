import Foundation

struct Target {
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
    /// Returns a new `Target` whose sets contain only the elements that are **not common to all** targets
    /// in the dictionary. For each property (filePaths, dependencies, frameworks):
    ///  - Compute the union of all sets
    ///  - Compute the intersection of all sets (elements present in every target)
    ///  - The resulting set is union minus intersection (elements that differ among targets)
    /// If the dictionary is empty, an empty target is returned.
    /// - Parameter name: Optional name for the resulting target (default: "Difference")
    func differenceTarget(named name: String = "Difference") -> Target {
        guard !isEmpty else {
            return Target(name: name, filePaths: [], dependencies: [], frameworks: [])
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
