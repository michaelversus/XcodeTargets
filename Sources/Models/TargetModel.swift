import Foundation

/// A value type that aggregates all relevant file path collections and metadata for a single Xcode target
/// discovered during project parsing. It keeps separate sets for buildable, source, and resource file paths
/// while also retaining dependency and framework relationships. A derived union of all file paths is stored
/// in `filePaths` for convenience.
struct TargetModel: Equatable {
    /// The unique target name as it appears in the Xcode project.
    let name: String
    /// All file paths in buildable folders (e.g. .swift, .m, .mm, .c, .cpp) that directly participate in compilation.
    let buildableFilePaths: Set<String>
    /// All file paths in groups (e.g. .swift, .m, .mm, .c, .cpp) that directly participate in compilation.
    let sourceFilePaths: Set<String>
    /// Resource file paths (e.g. asset catalogs, storyboards, xibs, json, image files) associated with the target.
    let resourceFilePaths: Set<String>
    /// Names of other targets this target depends on (target-level link dependencies like widget targets for example).
    let dependencies: Set<String>
    /// Names of frameworks linked by this target (system or custom frameworks).
    let frameworks: Set<String>
    /// Convenience union of all file paths (buildable ∪ source ∪ resource) for quick membership checks or iteration.
    let filePaths: Set<String>

    /// Creates a new `TargetModel` assigning each category of file paths. The consolidated `filePaths` union is
    /// computed automatically from the provided sets.
    /// - Parameters:
    ///   - name: The target's name.
    ///   - buildableFilePaths: Set of buildable file paths.
    ///   - sourceFilePaths: Set of source file paths.
    ///   - resourceFilePaths: Set of resource file paths.
    ///   - dependencies: Set of target dependency names.
    ///   - frameworks: Set of framework names.
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

    /// Maps the current `TargetModel` into a simpler `Target` domain entity that exposes only the aggregate file paths
    /// plus dependency and framework link information.
    /// - Returns: A `Target` constructed from this model's data.
    func mappingToTarget() -> Target {
        Target(
            name: name,
            filePaths: filePaths,
            dependencies: dependencies,
            frameworks: frameworks
        )
    }
}

// MARK: - TargetModel Value Transformations
extension TargetModel {
    /// Returns a new `TargetModel` instance with the provided buildable file path inserted. Existing data remains
    /// unchanged (value semantics). If the path already exists it is effectively a no-op due to set semantics.
    /// - Parameter path: The buildable file path to insert.
    /// - Returns: A new `TargetModel` containing the updated buildable file paths set.
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

// MARK: - Dictionary Convenience (TargetModel Aggregation)
extension Dictionary where Key == String, Value == TargetModel {
    /// Inserts a collection of buildable file paths into multiple targets, creating missing `TargetModel` entries
    /// on demand. Each target name in `targetNames` is updated independently.
    /// - Parameters:
    ///   - paths: Buildable file paths to insert.
    ///   - targetNames: Names of targets to update (created if absent).
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

    /// Inserts a collection of source file paths into multiple targets, creating missing `TargetModel` entries
    /// on demand.
    /// - Parameters:
    ///   - paths: Source file paths to insert.
    ///   - targetNames: Names of targets to update (created if absent).
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

    /// Inserts a collection of resource file paths into multiple targets, creating missing `TargetModel` entries
    /// on demand.
    /// - Parameters:
    ///   - paths: Resource file paths to insert.
    ///   - targetNames: Names of targets to update (created if absent).
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

    /// Prints a structured, sorted summary for each target using the provided printing closures. The summary includes
    /// counts and individual listings for buildable, source, resource, dependency, and framework sets.
    /// - Parameters:
    ///   - print: A closure used for normal output lines.
    ///   - vPrint: A closure that could be used for verbose output (currently unused but reserved for future expansion).
    func printSummary(
        print: @escaping (String) -> Void,
        vPrint: @escaping (String) -> Void
    ) {
        for (targetName, targetModel) in self.sorted(by: { $0.key < $1.key }) {
            let totalFilesCount = targetModel.buildableFilePaths.count +
            targetModel.sourceFilePaths.count +
            targetModel.resourceFilePaths.count
            print("Target: \(targetName) total files: \(totalFilesCount)")
            print("  Buildable files: \(targetModel.buildableFilePaths.count)")
            for buildableFilePath in targetModel.buildableFilePaths.sorted() {
                vPrint("\(targetName) - \(buildableFilePath)")
            }
            print("  Source files: \(targetModel.sourceFilePaths.count)")
            for sourceFilePath in targetModel.sourceFilePaths.sorted() {
                vPrint("\(targetName) - \(sourceFilePath)")
            }
            print("  Resource files: \(targetModel.resourceFilePaths.count)")
            for resourceFilePath in targetModel.resourceFilePaths.sorted() {
                vPrint("\(targetName) - \(resourceFilePath)")
            }
            print("  Dependencies: \(targetModel.dependencies.count)")
            for dependency in targetModel.dependencies.sorted() {
                vPrint("\(targetName) - \(dependency)")
            }
            print("  Frameworks: \(targetModel.frameworks.count)")
            for framework in targetModel.frameworks.sorted() {
                vPrint("\(targetName) - \(framework)")
            }
        }
    }
}
