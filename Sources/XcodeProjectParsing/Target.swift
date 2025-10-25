import Foundation

struct Target {
    let name: String
    let filePaths: Set<String>
    let dependencies: Set<String>
    let frameworks: Set<String>
}

extension Target {
    var containsNotEmptySets: Bool {
        !filePaths.isEmpty || !dependencies.isEmpty || !frameworks.isEmpty
    }
}

struct TargetModel {
    let name: String
    let buildableFilePaths: Set<String>
    let sourceFilePaths: Set<String>
    let resourceFilePaths: Set<String>
    let dependencies: Set<String>
    let frameworks: Set<String>
    let filePaths: Set<String>

    init(
        name: String,
        buildableFilePaths: Set<String>,
        sourceFilePaths: Set<String>,
        resourceFilePaths: Set<String>,
        dependencies: Set<String>,
        frameworks: Set<String>
    ) {
        self.name = name
        self.buildableFilePaths = buildableFilePaths
        self.sourceFilePaths = sourceFilePaths
        self.resourceFilePaths = resourceFilePaths
        self.dependencies = dependencies
        self.frameworks = frameworks
        self.filePaths = buildableFilePaths.union(sourceFilePaths).union(resourceFilePaths)
    }

    func mappingToTarget() -> Target {
        Target(
            name: name,
            filePaths: filePaths,
            dependencies: dependencies,
            frameworks: frameworks
        )
    }
}

extension TargetModel {
    func insertingBuildableFilePath(_ path: String) -> TargetModel {
        TargetModel(
            name: name,
            buildableFilePaths: buildableFilePaths.union([path]),
            sourceFilePaths: sourceFilePaths,
            resourceFilePaths: resourceFilePaths,
            dependencies: dependencies,
            frameworks: frameworks
        )
    }
}

extension Dictionary where Key == String, Value == TargetModel {
    mutating func insert(buildableFilePaths paths: Set<String>, forTargets targetNames: Set<String>) {
        for targetName in targetNames {
            let targetModel = self[targetName] ?? TargetModel(
                name: targetName,
                buildableFilePaths: [],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            )
            self[targetName] = TargetModel(
                name: targetModel.name,
                buildableFilePaths: targetModel.buildableFilePaths.union(paths),
                sourceFilePaths: targetModel.sourceFilePaths,
                resourceFilePaths: targetModel.resourceFilePaths,
                dependencies: targetModel.dependencies,
                frameworks: targetModel.frameworks
            )
        }
    }

    mutating func insert(sourceFilePaths paths: Set<String>, forTargets targetNames: Set<String>) {
        for targetName in targetNames {
            let targetModel = self[targetName] ?? TargetModel(
                name: targetName,
                buildableFilePaths: [],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            )
            self[targetName] = TargetModel(
                name: targetModel.name,
                buildableFilePaths: targetModel.buildableFilePaths,
                sourceFilePaths: targetModel.sourceFilePaths.union(paths),
                resourceFilePaths: targetModel.resourceFilePaths,
                dependencies: targetModel.dependencies,
                frameworks: targetModel.frameworks
            )
        }
    }

    mutating func insert(resourceFilePaths paths: Set<String>, forTargets targetNames: Set<String>) {
        for targetName in targetNames {
            let targetModel = self[targetName] ?? TargetModel(
                name: targetName,
                buildableFilePaths: [],
                sourceFilePaths: [],
                resourceFilePaths: [],
                dependencies: [],
                frameworks: []
            )
            self[targetName] = TargetModel(
                name: targetModel.name,
                buildableFilePaths: targetModel.buildableFilePaths,
                sourceFilePaths: targetModel.sourceFilePaths,
                resourceFilePaths: targetModel.resourceFilePaths.union(paths),
                dependencies: targetModel.dependencies,
                frameworks: targetModel.frameworks
            )
        }
    }

    func printSummary() {
        for (targetName, targetModel) in self.sorted(by: { $0.key < $1.key }) {
            print("MK Target: \(targetName) total files: \(targetModel.buildableFilePaths.count + targetModel.sourceFilePaths.count + targetModel.resourceFilePaths.count)")
            print("  Buildable files: \(targetModel.buildableFilePaths.count)")
            for buildableFilePath in targetModel.buildableFilePaths.sorted() {
                print("\(targetName)    - \(buildableFilePath)")
            }
            print("  Source files: \(targetModel.sourceFilePaths.count)")
            for sourceFilePath in targetModel.sourceFilePaths.sorted() {
                print(" \(targetName)   - \(sourceFilePath)")
            }
            print("  Resource files: \(targetModel.resourceFilePaths.count)")
            for resourceFilePath in targetModel.resourceFilePaths.sorted() {
                print("\(targetName)    - \(resourceFilePath)")
            }
            print("  Dependencies: \(targetModel.dependencies.count)")
            for dependency in targetModel.dependencies.sorted() {
                print("\(targetName)    - \(dependency)")
            }
            print("  Frameworks: \(targetModel.frameworks.count)")
            for framework in targetModel.frameworks.sorted() {
                print("\(targetName)    - \(framework)")
            }
        }
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
