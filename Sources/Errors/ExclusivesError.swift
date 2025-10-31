import Foundation

/// Enumerates validation failures encountered while processing exclusivity rules for targets.
///
/// These errors surface when:
/// - An exclusive section references a target name that does not exist.
/// - A declared exclusive file or folder path for a target cannot be found.
/// - Multiple targets declare entries that should be mutually exclusive.
///
/// Use these cases to surface actionable feedback to the caller or user.
enum ExclusivesError: Error, CustomStringConvertible, Equatable {
    /// The exclusive section referenced a target name that does not exist in the parsed Xcode project.
    /// - Parameter name: The unknown target name.
    case invalidTargetName(String)

    /// A declared exclusive path for a specific target does not exist in the project's file system context.
    /// - Parameters:
    ///   - targetName: The name of the target whose exclusive path is invalid.
    ///   - path: The missing or malformed path string.
    case invalidPathForTarget(targetName: String, path: String)

    /// Conflicting exclusive entries were found across the provided targets (duplicates in mutually exclusive sections).
    /// - Parameter targetNames: A comma-separated list of conflicting target names.
    /// - Parameter diff: A `Target` instance representing the differences found.
    case exclusiveEntriesFound(targetNames: String, diff: Target)

    /// A human-readable description of the exclusivity validation failure, suitable for logging or displaying in diagnostics.
    var description: String {
        switch self {
        case .invalidTargetName(let name):
            "❌ Target name \(name) inside exclusive section doesn't exist in the project"
        case .invalidPathForTarget(let targetName, let path):
            "❌ Path \(path) inside exclusive section for target \(targetName) doesn't exist in the project"
        case .exclusiveEntriesFound(let targetNames, let diff):
            exclusiveEntriesErrorMessage(
                targetNames: targetNames,
                diff: diff
            )
        }
    }

    private func exclusiveEntriesErrorMessage(
        targetNames: String,
        diff: Target
    ) -> String {
        var message = "❌ Exclusive entries found for targets: \(targetNames)\n"
        updateMessage(
            kind: "files",
            entries: diff.filePaths,
            message: &message
        )
        updateMessage(
            kind: "dependencies",
            entries: diff.dependencies,
            message: &message
        )
        updateMessage(
            kind: "frameworks",
            entries: diff.frameworks,
            message: &message
        )
        return message
    }

    private func updateMessage(
        kind: String,
        entries: Set<String>,
        message: inout String
    ) {
        guard !entries.isEmpty else { return }
        message += " Conflicting \(kind):\n"
        for entry in entries.sorted() {
            message += " - \(entry)\n"
        }
    }
}
